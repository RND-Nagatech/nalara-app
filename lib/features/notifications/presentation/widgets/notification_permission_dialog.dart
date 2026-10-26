import 'package:flutter/material.dart';
import '../../../../utils/color.dart';

/// An explanation from NALARA, not an imitation of the system permission alert.
class NotificationPermissionDialog extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onEnable, onLater;
  const NotificationPermissionDialog({
    super.key,
    required this.busy,
    required this.onEnable,
    required this.onLater,
    this.error,
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Dialog(
      constraints: const BoxConstraints(maxWidth: 380),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: NalaraColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: NalaraColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 108,
                height: 108,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NalaraColors.lightGreen,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: NalaraColors.surface, width: 3),
                ),
                child: Image.asset(
                  'assets/Logo/LOGO.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Logo NALARA',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              namesRoute: true,
              header: true,
              child: const Text(
                'Aktifkan notifikasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: NalaraColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Jangan lewatkan jadwal les dan kabar terbaru tentang target, tugas, serta laporan belajar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NalaraInter',
                fontSize: 14,
                height: 1.6,
                color: NalaraColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Setelah ini, perangkat atau browser akan meminta persetujuanmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NalaraInter',
                fontSize: 11.5,
                height: 1.5,
                color: NalaraColors.muted,
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: NalaraColors.danger,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            FilledButton(
              key: const ValueKey('notification-permission-enable'),
              onPressed: busy ? null : onEnable,
              style: FilledButton.styleFrom(
                backgroundColor: NalaraColors.green,
                foregroundColor: NalaraColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: NalaraColors.surface,
                      ),
                    )
                  : const Text(
                      'Aktifkan notifikasi',
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: const ValueKey('notification-permission-later'),
              onPressed: busy ? null : onLater,
              style: TextButton.styleFrom(
                foregroundColor: NalaraColors.muted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              child: const Text('Nanti saja'),
            ),
          ],
        ),
      ),
    ),
  );
}
