import 'dart:async';
import 'package:nalara/features/account_deletion/domain/account_deletion.dart';

const deletionAccount = AccountDeletionSummary(
  userId: 'teacher-a',
  email: 'guru@example.test',
  phone: '+6281234567890',
  processingNotice:
      'Akses ditutup setelah konfirmasi. Data dihapus otomatis oleh server.',
  googleLinked: false,
  openPayment: false,
  students: 2,
  schedules: 3,
  targets: 4,
  reports: 5,
);

class DeletionFake implements AccountDeletionRepository {
  AccountDeletionSummary value = deletionAccount;
  Object? loadError, removeError;
  Completer<AccountDeletionSummary>? readGate;
  Completer<AccountDeletionReceipt>? removeGate;
  int reads = 0, removals = 0;
  String? password;
  DeletionVerification? method;
  @override
  Future<AccountDeletionSummary> summary() async {
    reads++;
    if (loadError != null) throw loadError!;
    return readGate?.future ?? value;
  }

  @override
  Future<AccountDeletionReceipt> remove({
    required AccountDeletionSummary account,
    required DeletionVerification verification,
    required String password,
  }) async {
    removals++;
    this.password = password;
    method = verification;
    if (removeError != null) throw removeError!;
    return removeGate?.future ??
        const AccountDeletionReceipt('Permintaan penghapusan diterima.');
  }
}
