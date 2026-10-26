import 'package:flutter/material.dart';
import '../../../utils/color.dart';
import '../domain/subscription.dart';
import 'subscription_format.dart';

class SubscriptionPaymentCard extends StatelessWidget {
  final SubscriptionPayment payment;
  final bool busy;
  final VoidCallback onContinue, onRefresh, onCancel;
  const SubscriptionPaymentCard({
    super.key,
    required this.payment,
    required this.busy,
    required this.onContinue,
    required this.onRefresh,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: NalaraColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${payment.plan == 'pro' ? 'Tutor Pro' : 'Tutor Basic'} · ${rupiah(payment.amount)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          payment.reference,
          style: const TextStyle(fontSize: 11, color: NalaraColors.muted),
        ),
        Text(
          switch (payment.status) {
            'paid' => 'Pembayaran berhasil',
            'cancelled' => 'Order dibatalkan',
            'failed' => 'Pembuatan pembayaran gagal',
            'creating' => 'Tautan pembayaran belum tersedia',
            'pending' =>
              payment.canContinue
                  ? 'Menunggu pembayaran'
                  : 'Tautan pembayaran belum tersedia',
            _ => 'Status pembayaran belum dikenali',
          },
          style: TextStyle(
            color: payment.paid ? NalaraColors.green : NalaraColors.muted,
            height: 1.8,
          ),
        ),
        if (payment.open && !payment.canContinue)
          const Text(
            'Belum dinyatakan terbayar. Periksa atau batalkan order ini sebelum membuat order baru.',
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: NalaraColors.muted,
            ),
          ),
        if (payment.open)
          Wrap(
            spacing: 10,
            children: [
              if (payment.canContinue)
                TextButton(
                  onPressed: busy ? null : onContinue,
                  child: const Text('Lanjutkan pembayaran'),
                ),
              TextButton(
                onPressed: busy ? null : onRefresh,
                child: const Text('Periksa pembayaran'),
              ),
              TextButton(
                onPressed: busy ? null : onCancel,
                child: const Text('Batalkan'),
              ),
            ],
          ),
      ],
    ),
  );
}
