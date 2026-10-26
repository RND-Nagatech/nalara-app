import 'package:flutter/material.dart';
import '../../../shared/widgets/nalara_celebration_sheet.dart';

class TutorialCompletionSheet extends StatelessWidget {
  static const artwork = 'assets/Succes/Succes.png';
  final VoidCallback onDismiss;
  const TutorialCompletionSheet({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) => NalaraCelebrationSheet(
    artwork: artwork,
    eyebrow: 'AWAL YANG HEBAT',
    title: 'Selamat, Anda siap mengajar!',
    message:
        'Empat langkah utama sudah selesai.\nAnda dapat menghubungkan Orang Tua dan mengatur biaya bimbel sebagai langkah opsional di Lainnya → Panduan mulai mengajar.',
    keyPrefix: 'tutorial-completion',
    effect: NalaraCelebrationEffect.confetti,
    onDismiss: onDismiss,
  );
}
