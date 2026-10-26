import 'dart:async';
import 'subscription.dart';
import 'subscription_repository.dart';

/// Cosmetic receipts only. These IDs never grant or extend an entitlement.
class PaymentCelebrationReceipts {
  final Set<String> pending, acknowledged;
  PaymentCelebrationReceipts({
    Iterable<String> pending = const [],
    Iterable<String> acknowledged = const [],
  }) : pending = Set.unmodifiable(pending),
       acknowledged = Set.unmodifiable(acknowledged);
}

abstract interface class PaymentCelebrationStore {
  Future<PaymentCelebrationReceipts> read(String accountId);
  Future<void> write(String accountId, PaymentCelebrationReceipts receipts);
}

class PaymentCelebrations {
  final SubscriptionRepository repository;
  final PaymentCelebrationStore store;
  Future<void> _tail = Future.value();
  final Set<String> _dismissed = {};
  final Map<String, PaymentCelebrationReceipts> _cache = {};
  PaymentCelebrations(this.repository, this.store);

  Future<PaymentCelebrationReceipts> _read(String accountId) async {
    if (_cache.containsKey(accountId)) return _cache[accountId]!;
    try {
      return _cache[accountId] = await store.read(accountId);
    } catch (_) {
      // A cosmetic storage outage can degrade to in-session deduplication.
      return _cache[accountId] = PaymentCelebrationReceipts();
    }
  }

  Future<void> _write(
    String accountId,
    PaymentCelebrationReceipts receipts,
  ) async {
    _cache[accountId] = receipts;
    await store.write(accountId, receipts);
  }

  // Serialize receipt updates, including refreshes racing with dismissal.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> watch(String accountId, SubscriptionPayment payment) =>
      _serial(() async {
        if (!['basic', 'pro'].contains(payment.plan) ||
            !['creating', 'pending', 'paid'].contains(payment.status)) {
          return;
        }
        final receipts = await _read(accountId);
        if (receipts.acknowledged.contains(payment.id) ||
            _dismissed.contains('$accountId/${payment.id}') ||
            receipts.pending.contains(payment.id)) {
          return;
        }
        await _write(
          accountId,
          PaymentCelebrationReceipts(
            pending: {...receipts.pending, payment.id},
            acknowledged: receipts.acknowledged,
          ),
        );
      });

  Future<SubscriptionPayment?> find(
    String accountId,
    TutorSubscription subscription,
  ) => _serial(() async {
    if (!subscription.active || subscription.plan == 'trial') return null;
    final receipts = await _read(accountId);
    if (receipts.pending.isEmpty) return null;
    final history = await repository.payments(1);
    for (final payment in history.items) {
      if (payment.paid &&
          payment.plan == subscription.plan &&
          receipts.pending.contains(payment.id) &&
          !receipts.acknowledged.contains(payment.id) &&
          !_dismissed.contains('$accountId/${payment.id}')) {
        return payment;
      }
    }
    return null;
  });

  Future<void> acknowledge(String accountId, String paymentId) {
    _dismissed.add('$accountId/$paymentId');
    return _serial(() async {
      final receipts = await _read(accountId);
      await _write(
        accountId,
        PaymentCelebrationReceipts(
          pending: receipts.pending.where((id) => id != paymentId),
          acknowledged: {...receipts.acknowledged, paymentId},
        ),
      );
    });
  }
}
