import '../../../shared/network/token_store.dart';
import '../../auth/data/datasources/remembered_login_local_source.dart';
import '../../auth/data/services/google_auth_service.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../auth/domain/value_objects/phone_number.dart';
import '../domain/account_deletion.dart';
import 'account_deletion_model.dart';
import 'account_deletion_remote_source.dart';

class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  final AccountDeletionRemoteSource remote;
  final TokenStore tokens;
  final RememberedLoginLocalSource remembered;
  final GoogleAuthService google;
  const AccountDeletionRepositoryImpl(
    this.remote,
    this.tokens,
    this.remembered,
    this.google,
  );

  @override
  Future<AccountDeletionSummary> summary() async =>
      AccountDeletionModel(await remote.summary()).summary();

  @override
  Future<AccountDeletionReceipt> remove({
    required AccountDeletionSummary account,
    required DeletionVerification verification,
    required String password,
  }) async {
    final sessionBefore = tokens.sessionGeneration;
    final idToken = verification == DeletionVerification.google
        ? await google.signIn()
        : null;
    final result = AccountDeletionModel(
      await remote.remove(
        expectedSessionGeneration: sessionBefore,
        password: verification == DeletionVerification.password
            ? password
            : null,
        idToken: idToken,
      ),
    ).receiptMessage();
    // Cleanup begins only after an explicit accepted response. A failed proof
    // or cancelled Google dialog must leave the Nalara session intact.
    var localFailure = false;
    bool sameSession() => tokens.sessionGeneration == sessionBefore;
    try {
      final saved = await remembered.read();
      if (sameSession() && saved != null) {
        final phone = account.phone == null
            ? null
            : PhoneNumber.normalize(account.phone!);
        final matches = saved.method == LoginMethod.email
            ? saved.identifier.trim().toLowerCase() ==
                  account.email.toLowerCase()
            : phone != null && PhoneNumber.normalize(saved.identifier) == phone;
        if (matches) await remembered.clear();
      }
    } catch (_) {
      localFailure = true;
    }
    if (sameSession()) {
      final clearedSession = sessionBefore + 1;
      try {
        await tokens.clear();
      } catch (_) {
        localFailure = true;
      }
      if (tokens.sessionGeneration == clearedSession &&
          tokens.accessToken == null) {
        try {
          await google.signOut();
        } catch (_) {
          localFailure = true;
        }
      }
    }
    return AccountDeletionReceipt(result, localCleanupIncomplete: localFailure);
  }
}
