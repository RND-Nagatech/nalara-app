import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/subscription/domain/subscription.dart';
import 'package:nalara/features/subscription/presentation/subscription_payment_card.dart';

SubscriptionPayment payment(String status, {String? url}) =>
    SubscriptionPayment(
      id: 'order-a',
      reference: 'NLR-a',
      plan: 'basic',
      status: status,
      amount: 39000,
      createdAt: DateTime.utc(2026, 10, 19),
      checkoutUrl: url,
    );

void main() {
  test('only open orders with valid HTTPS links can be continued', () {
    for (final status in ['creating', 'pending']) {
      expect(
        payment(status, url: 'https://checkout.invalid/a').canContinue,
        isTrue,
      );
      for (final url in [
        null,
        '',
        'https://',
        'http://checkout.invalid',
        'javascript:alert(1)',
      ]) {
        expect(payment(status, url: url).canContinue, isFalse);
      }
    }
    for (final status in ['paid', 'failed', 'cancelled', 'unknown']) {
      expect(payment(status, url: 'https://checkout.invalid/a').open, isFalse);
      expect(
        payment(status, url: 'https://checkout.invalid/a').canContinue,
        isFalse,
      );
    }
  });

  for (final entry in const {
    'creating': 'Tautan pembayaran belum tersedia',
    'pending': 'Menunggu pembayaran',
    'paid': 'Pembayaran berhasil',
    'failed': 'Pembuatan pembayaran gagal',
    'cancelled': 'Order dibatalkan',
  }.entries) {
    testWidgets(
      'renders ${entry.key} distinctly and keeps terminal orders closed',
      (tester) async {
        var refreshed = 0, cancelled = 0;
        final row = payment(
          entry.key,
          url: entry.key == 'creating' ? null : 'https://checkout.invalid/a',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SubscriptionPaymentCard(
                  payment: row,
                  busy: false,
                  onContinue: () {},
                  onRefresh: () => refreshed++,
                  onCancel: () => cancelled++,
                ),
              ),
            ),
          ),
        );
        expect(find.text(entry.value), findsOneWidget);
        if (row.open) {
          await tester.tap(find.text('Periksa pembayaran'));
          await tester.tap(find.text('Batalkan'));
          expect(refreshed, 1);
          expect(cancelled, 1);
          expect(
            find.text('Lanjutkan pembayaran'),
            row.canContinue ? findsOneWidget : findsNothing,
          );
        } else {
          expect(find.text('Batalkan'), findsNothing);
          expect(find.text('Periksa pembayaran'), findsNothing);
          expect(find.text('Lanjutkan pembayaran'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'busy disables all actions and narrow large-text card stays scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SubscriptionPaymentCard(
                payment: payment('pending', url: 'https://checkout.invalid/a'),
                busy: true,
                onContinue: () => fail('busy'),
                onRefresh: () => fail('busy'),
                onCancel: () => fail('busy'),
              ),
            ),
          ),
        ),
      );
      for (final button in tester.widgetList<TextButton>(
        find.byType(TextButton),
      )) {
        expect(button.onPressed, isNull);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
