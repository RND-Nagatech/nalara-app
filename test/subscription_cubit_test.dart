import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/subscription/domain/subscription.dart';
import 'package:nalara/features/subscription/domain/subscription_repository.dart';
import 'package:nalara/features/subscription/presentation/subscription_cubit.dart';

TutorSubscription subscription(String plan, {String? warning}) {
  final now = DateTime.now();
  return TutorSubscription(
    plan: plan,
    status: plan == 'trial' ? 'trialing' : 'active',
    active: true,
    checkoutEnabled: true,
    daysRemaining: 1,
    activeStudents: 1,
    trialDays: 14,
    endsAt: now.add(const Duration(hours: 1)),
    serverNow: now,
    studentLimit: plan == 'pro' ? null : 5,
    features: const [],
    featureLabels: const {},
    plans: const [],
    paymentSyncWarning: warning,
  );
}

class SubscriptionFake implements SubscriptionRepository {
  int reads = 0, synchronizations = 0;
  TutorSubscription value = subscription('trial');
  Completer<TutorSubscription>? readGate, syncGate;
  @override
  Future<TutorSubscription> current() {
    reads++;
    return readGate?.future ?? Future.value(value);
  }

  @override
  Future<TutorSubscription> synchronize() {
    synchronizations++;
    return syncGate?.future ?? Future.value(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'login synchronizes existing payments instead of merely reading Trial',
    () async {
      final repo = SubscriptionFake()..value = subscription('pro');
      final cubit = SubscriptionCubit(repo);
      addTearDown(cubit.close);
      await cubit.activate('teacher-a');
      expect(repo.synchronizations, 1);
      expect(repo.reads, 0);
      expect(cubit.state.value?.plan, 'pro');
    },
  );

  test('a late Trial GET cannot overwrite the synchronized Pro plan', () async {
    final repo = SubscriptionFake();
    final cubit = SubscriptionCubit(repo);
    addTearDown(cubit.close);
    await cubit.activate('teacher-a');
    repo.readGate = Completer<TutorSubscription>();
    final stale = cubit.refresh();
    repo.value = subscription('pro');
    await cubit.refresh(synchronizePayment: true);
    repo.readGate!.complete(subscription('trial'));
    await stale;
    expect(cubit.state.value?.plan, 'pro');
  });

  test(
    'simultaneous resume and manual refresh share one payment sync',
    () async {
      final repo = SubscriptionFake();
      final cubit = SubscriptionCubit(repo);
      addTearDown(cubit.close);
      await cubit.activate('teacher-a');
      repo.syncGate = Completer<TutorSubscription>();
      final resume = cubit.refresh(synchronizePayment: true);
      final manual = cubit.refresh(synchronizePayment: true);
      expect(repo.synchronizations, 2);
      repo.syncGate!.complete(subscription('pro'));
      await Future.wait([resume, manual]);
      expect(cubit.state.value?.plan, 'pro');
    },
  );

  test(
    'an old account sync cannot replace another account subscription',
    () async {
      final repo = SubscriptionFake()
        ..syncGate = Completer<TutorSubscription>();
      final oldGate = repo.syncGate!;
      final cubit = SubscriptionCubit(repo);
      addTearDown(cubit.close);
      final old = cubit.activate('teacher-a');
      repo.syncGate = Completer<TutorSubscription>();
      final current = cubit.activate('teacher-b');
      repo.syncGate!.complete(subscription('basic'));
      await current;
      oldGate.complete(subscription('pro'));
      await old;
      expect(cubit.accountId, 'teacher-b');
      expect(cubit.state.value?.plan, 'basic');
    },
  );

  test('provider sync warnings retain the actual server entitlement', () async {
    final repo = SubscriptionFake()
      ..value = subscription(
        'basic',
        warning: 'Status pembayaran belum dapat disinkronkan.',
      );
    final cubit = SubscriptionCubit(repo);
    addTearDown(cubit.close);
    await cubit.activate('teacher-a');
    expect(cubit.state.value?.plan, 'basic');
    expect(cubit.state.blocked, isFalse);
    expect(cubit.state.error, contains('belum dapat disinkronkan'));
  });
}
