import 'package:flutter/material.dart';
import 'notifications_style.dart';

class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Image.asset(
            NotificationsStyle.emptyArtwork,
            key: const ValueKey('notifications-empty-artwork'),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Belum ada notifikasi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 21,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: NotificationsStyle.ink,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Update yang dibagikan dan laporan terbit akan muncul di sini.',
          textAlign: TextAlign.center,
          style: NotificationsStyle.body,
        ),
      ],
    ),
  );
}
