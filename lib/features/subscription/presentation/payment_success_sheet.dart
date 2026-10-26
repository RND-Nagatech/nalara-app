import 'package:flutter/material.dart';
import '../../../shared/widgets/nalara_celebration_sheet.dart';

class PaymentSuccessSheet extends StatelessWidget {
  static const artwork = 'assets/paid/Paid.png';
  final String planName;
  final VoidCallback onDismiss;
  const PaymentSuccessSheet({
    super.key,
    required this.planName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => NalaraCelebrationSheet(
    artwork: artwork,
    eyebrow: 'PEMBAYARAN BERHASIL',
    title: 'Selamat menikmati paket $planName!',
    message:
        'Pembayaran Anda telah dikonfirmasi dan paket sudah aktif.\nTerima kasih telah bertumbuh bersama NALARA.',
    keyPrefix: 'payment-success',
    effect: NalaraCelebrationEffect.sparkles,
    onDismiss: onDismiss,
  );
}
