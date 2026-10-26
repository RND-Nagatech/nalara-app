import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/payment_celebrations.dart';

class PaymentCelebrationLocalSource implements PaymentCelebrationStore {
  final FlutterSecureStorage storage;
  const PaymentCelebrationLocalSource(this.storage);
  String _key(String accountId) => 'payment-celebrations-v1-$accountId';

  @override
  Future<PaymentCelebrationReceipts> read(String accountId) async {
    final value = await storage.read(key: _key(accountId));
    if (value == null) return PaymentCelebrationReceipts();
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return PaymentCelebrationReceipts(
        pending: List<String>.from(json['pending'] as List),
        acknowledged: List<String>.from(json['acknowledged'] as List),
      );
    } on FormatException {
      return PaymentCelebrationReceipts();
    } on TypeError {
      return PaymentCelebrationReceipts();
    }
  }

  @override
  Future<void> write(String accountId, PaymentCelebrationReceipts receipts) =>
      storage.write(
        key: _key(accountId),
        value: jsonEncode({
          'pending': receipts.pending.toList(),
          'acknowledged': receipts.acknowledged.toList(),
        }),
      );
}
