import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/account_deletion.dart';

class AccountDeletionState {
  final AccountDeletionSummary? account;
  final bool loading, submitting, summaryUnavailable;
  final String? error;
  const AccountDeletionState({
    this.account,
    this.loading = false,
    this.submitting = false,
    this.summaryUnavailable = false,
    this.error,
  });
  bool get busy => loading || submitting;
}

class AccountDeletionCubit extends Cubit<AccountDeletionState> {
  final AccountDeletionRepository repository;
  int _generation = 0;
  AccountDeletionCubit(this.repository) : super(const AccountDeletionState());

  Future<void> load() async {
    if (isClosed || state.submitting) return;
    final generation = ++_generation;
    emit(AccountDeletionState(account: state.account, loading: true));
    try {
      final account = await repository.summary();
      if (!isClosed && generation == _generation) {
        emit(AccountDeletionState(account: account));
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          AccountDeletionState(
            account: state.account,
            summaryUnavailable: true,
            error: error.toString(),
          ),
        );
      }
    }
  }

  Future<AccountDeletionReceipt?> remove({
    required DeletionVerification verification,
    required String password,
  }) async {
    final account = state.account;
    if (isClosed || state.busy || account == null || state.summaryUnavailable) {
      return null;
    }
    final generation = ++_generation;
    emit(AccountDeletionState(account: account, submitting: true));
    try {
      final receipt = await repository.remove(
        account: account,
        verification: verification,
        password: password,
      );
      // The caller still finishes local sign-out after a hidden/disposed page
      // receives acceptance, without showing notices on an unrelated route.
      if (!isClosed && generation == _generation) {
        emit(AccountDeletionState(account: account));
      }
      return receipt;
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(AccountDeletionState(account: account, error: error.toString()));
      }
      return null;
    }
  }

  void clearError() {
    if (!isClosed &&
        !state.busy &&
        state.account != null &&
        !state.summaryUnavailable) {
      emit(AccountDeletionState(account: state.account));
    }
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
