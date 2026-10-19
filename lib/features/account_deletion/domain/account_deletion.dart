enum DeletionVerification { password, google }

class AccountDeletionSummary {
  final String userId, email, processingNotice;
  final String? phone;
  final bool googleLinked, openPayment;
  final int students, schedules, targets, reports;
  const AccountDeletionSummary({
    required this.userId,
    required this.email,
    this.phone,
    required this.processingNotice,
    required this.googleLinked,
    required this.openPayment,
    required this.students,
    required this.schedules,
    required this.targets,
    required this.reports,
  });
}

class AccountDeletionReceipt {
  final String message;
  final bool localCleanupIncomplete;
  const AccountDeletionReceipt(
    this.message, {
    this.localCleanupIncomplete = false,
  });
}

abstract interface class AccountDeletionRepository {
  Future<AccountDeletionSummary> summary();
  Future<AccountDeletionReceipt> remove({
    required AccountDeletionSummary account,
    required DeletionVerification verification,
    required String password,
  });
}
