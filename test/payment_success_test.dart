import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/subscription/domain/payment_celebrations.dart';
import 'package:nalara/features/subscription/domain/subscription.dart';
import 'package:nalara/features/subscription/presentation/payment_success_host.dart';
import 'package:nalara/features/subscription/presentation/payment_success_sheet.dart';
import 'package:nalara/features/subscription/presentation/subscription_cubit.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/widgets/nalara_celebration_sheet.dart';
import 'subscription_cubit_test.dart' show SubscriptionFake, subscription;

SubscriptionPayment order(
  String id, {
  String plan = 'pro',
  String status = 'pending',
}) => SubscriptionPayment(
  id: id,
  reference: 'order-$id',
  plan: plan,
  status: status,
  amount: 1,
  createdAt: DateTime.utc(2026, 10, 19),
);

class ReceiptMemory implements PaymentCelebrationStore {
  final Map<String, PaymentCelebrationReceipts> values = {};
  @override
  Future<PaymentCelebrationReceipts> read(String accountId) async =>
      values[accountId] ?? PaymentCelebrationReceipts();
  @override
  Future<void> write(
    String accountId,
    PaymentCelebrationReceipts receipts,
  ) async => values[accountId] = receipts;
}

class PaymentFake extends SubscriptionFake {
  List<SubscriptionPayment> history = [];
  Completer<PageResult<SubscriptionPayment>>? historyGate;
  bool failHistory = false;
  @override
  Future<PageResult<SubscriptionPayment>> payments(int page) async {
    if (failHistory) throw StateError('history unavailable');
    return historyGate?.future ??
        PageResult(
          items: history,
          total: history.length,
          page: page,
          limit: 10,
        );
  }
}

void main() {
  late PaymentFake repo;
  late ReceiptMemory receipts;
  late PaymentCelebrations celebrations;
  setUp(() {
    repo = PaymentFake();
    receipts = ReceiptMemory();
    celebrations = PaymentCelebrations(repo, receipts);
  });

  test('pending, failed, wrong-plan and Trial never celebrate', () async {
    await celebrations.watch('a', order('1'));
    for (final status in ['pending', 'creating', 'failed']) {
      repo.history = [order('1', status: status)];
      expect(await celebrations.find('a', subscription('pro')), isNull);
    }
    repo.history = [order('1', status: 'paid')];
    expect(await celebrations.find('a', subscription('trial')), isNull);
    expect(await celebrations.find('a', subscription('basic')), isNull);
    expect(await celebrations.find('a', subscription('pro')), repo.history[0]);
  });

  test('old paid history without a watched checkout is not replayed', () async {
    repo.history = [order('old', status: 'paid')];
    expect(await celebrations.find('a', subscription('pro')), isNull);
  });

  test(
    'dismissal persists per order, account and application restart',
    () async {
      await celebrations.watch('a', order('1'));
      repo.history = [order('1', status: 'paid')];
      expect(await celebrations.find('b', subscription('pro')), isNull);
      await celebrations.acknowledge('a', '1');
      final restarted = PaymentCelebrations(repo, receipts);
      await restarted.watch('a', repo.history[0]);
      expect(await restarted.find('a', subscription('pro')), isNull);
      await restarted.watch('a', order('renewal'));
      repo.history = [order('renewal', status: 'paid')];
      expect((await restarted.find('a', subscription('pro')))?.id, 'renewal');
    },
  );

  test('resumed account finds paid watched checkout after restart', () async {
    await celebrations.watch('a', order('1', plan: 'basic'));
    repo.value = subscription('basic');
    repo.history = [order('1', plan: 'basic', status: 'paid')];
    final cubit = SubscriptionCubit(
      repo,
      celebrations: PaymentCelebrations(repo, receipts),
    );
    addTearDown(cubit.close);
    await cubit.activate('a');
    expect(cubit.state.confirmedPayment?.plan, 'basic');
    final receipt = cubit.state.confirmedPayment;
    await cubit.refresh(synchronizePayment: true);
    expect(cubit.state.confirmedPayment, same(receipt));
    cubit.dismissPayment('1');
    await cubit.refresh(synchronizePayment: true);
    expect(cubit.state.confirmedPayment, isNull);
    expect(cubit.state.value?.plan, 'basic');
  });

  test(
    'late old-account receipt is ignored after switching accounts',
    () async {
      await celebrations.watch('a', order('1'));
      repo.value = subscription('pro');
      repo.historyGate = Completer<PageResult<SubscriptionPayment>>();
      final gate = repo.historyGate!;
      final cubit = SubscriptionCubit(repo, celebrations: celebrations);
      addTearDown(cubit.close);
      final old = cubit.activate('a');
      await Future<void>.delayed(Duration.zero);
      repo.historyGate = null;
      repo.value = subscription('basic');
      final current = cubit.activate('b');
      gate.complete(
        PageResult(
          items: [order('1', status: 'paid')],
          total: 1,
          page: 1,
          limit: 10,
        ),
      );
      await Future.wait([old, current]);
      expect(cubit.accountId, 'b');
      expect(cubit.state.confirmedPayment, isNull);
      expect(cubit.state.value?.plan, 'basic');
    },
  );

  test(
    'receipt failure never revokes verified plan; next sync retries',
    () async {
      await celebrations.watch('a', order('1'));
      repo.value = subscription('pro');
      repo.failHistory = true;
      final cubit = SubscriptionCubit(repo, celebrations: celebrations);
      addTearDown(cubit.close);
      await cubit.activate('a');
      expect(cubit.state.blocked, isFalse);
      expect(cubit.state.confirmedPayment, isNull);
      repo.failHistory = false;
      repo.history = [order('1', status: 'paid')];
      await cubit.refresh(synchronizePayment: true);
      expect(cubit.state.confirmedPayment?.id, '1');
    },
  );

  testWidgets('small screen, large text and reduced motion keep bottom safe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var visible = true;
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.8),
            padding: const EdgeInsets.only(bottom: 48),
            viewPadding: const EdgeInsets.only(bottom: 48),
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Stack(
              fit: StackFit.expand,
              children: [
                child!,
                if (visible)
                  PaymentSuccessSheet(
                    planName: 'Pro',
                    onDismiss: () => setState(() => visible = false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
    final hint = find.text(
      'Ketuk di mana saja atau tarik ke bawah untuk menutup.',
    );
    expect(tester.getBottomLeft(hint).dy, lessThanOrEqualTo(640 - 48));
    await tester.tap(hint);
    await tester.pump();
    expect(find.byType(PaymentSuccessSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final gesture in ['image', 'outside', 'drag']) {
    testWidgets(
      'paid sheet and sparkles appear together; dismiss by $gesture',
      (tester) async {
        final plan = gesture == 'image' ? 'basic' : 'pro';
        final name = plan == 'basic' ? 'Basic' : 'Pro';
        await celebrations.watch('a', order('1', plan: plan));
        repo.value = subscription(plan);
        repo.history = [order('1', plan: plan, status: 'paid')];
        final cubit = SubscriptionCubit(repo, celebrations: celebrations);
        addTearDown(cubit.close);
        await cubit.activate('a');
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 48),
                viewPadding: const EdgeInsets.only(bottom: 48),
              ),
              child: PaymentSuccessHost(
                subscription: cubit,
                teacherId: 'a',
                child: child!,
              ),
            ),
            home: const Scaffold(body: Text('Langganan')),
          ),
        );
        expect(
          find.byKey(const ValueKey('payment-success-sheet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('payment-success-sparkles')),
          findsOneWidget,
        );
        expect(find.text('Selamat menikmati paket $name!'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('payment-success-confetti')),
          findsNothing,
        );
        expect(find.byIcon(Icons.close), findsNothing);
        expect(find.byIcon(Icons.close_rounded), findsNothing);
        final image = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  PaymentSuccessSheet.artwork,
        );
        expect(tester.widget<Image>(image).fit, BoxFit.contain);
        await tester.pumpAndSettle();
        final scroll = find.descendant(
          of: find.byType(NalaraCelebrationSheet),
          matching: find.byType(SingleChildScrollView),
        );
        final padding = tester
            .widget<SingleChildScrollView>(scroll)
            .padding!
            .resolve(TextDirection.ltr);
        expect(padding.bottom, 76);
        final sheet = tester.state(find.byType(NalaraCelebrationSheet));
        await cubit.refresh(synchronizePayment: true);
        await tester.pump();
        expect(tester.state(find.byType(NalaraCelebrationSheet)), same(sheet));
        switch (gesture) {
          case 'image':
            await tester.tap(image);
          case 'outside':
            await tester.tapAt(const Offset(8, 8));
          case 'drag':
            await tester.drag(
              find.byKey(const ValueKey('payment-success-drag-handle')),
              const Offset(0, 550),
            );
        }
        await tester.pumpAndSettle();
        expect(find.byType(PaymentSuccessSheet), findsNothing);
        expect(cubit.state.confirmedPayment, isNull);
        expect(cubit.state.value?.plan, plan);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
