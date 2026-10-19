import '../../../shared/errors/app_failure.dart';
import '../domain/account_deletion.dart';

class AccountDeletionModel {
  final Map<String, dynamic> json;
  const AccountDeletionModel(this.json);

  Never _invalid() => throw const AppFailure(
    'Data penghapusan akun belum sesuai. Muat ulang dan periksa backend.',
    code: 'INVALID_RESPONSE',
  );
  String _text(String key) =>
      json[key] is String && (json[key] as String).isNotEmpty
      ? json[key] as String
      : _invalid();
  bool _flag(String key) => json[key] is bool ? json[key] as bool : _invalid();
  int _count(String key) => json[key] is int && (json[key] as int) >= 0
      ? json[key] as int
      : _invalid();
  String? _phone() => json['phone'] == null || json['phone'] is String
      ? json['phone'] as String?
      : _invalid();

  AccountDeletionSummary summary() => AccountDeletionSummary(
    userId: _text('userId'),
    email: _text('email'),
    phone: _phone(),
    processingNotice: _text('processingNotice'),
    googleLinked: _flag('googleLinked'),
    openPayment: _flag('openPayment'),
    students: _count('students'),
    schedules: _count('schedules'),
    targets: _count('targets'),
    reports: _count('reports'),
  );

  String receiptMessage() {
    if (json['accepted'] != true || json['status'] != 'pending') _invalid();
    return _text('message');
  }
}
