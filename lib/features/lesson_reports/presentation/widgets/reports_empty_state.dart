import 'package:flutter/material.dart';
import 'reports_style.dart';

class ReportsEmptyState extends StatelessWidget {
  final String? status;
  final VoidCallback onAdd;
  final bool showAction;

  const ReportsEmptyState({
    super.key,
    required this.status,
    required this.onAdd,
    this.showAction = true,
  });

  String get _title => switch (status) {
    'draft' => 'Belum ada draft laporan.',
    'published' => 'Belum ada laporan terbit.',
    _ => 'Belum ada laporan belajar.',
  };

  String get _description => switch (status) {
    'draft' => 'Draft laporan yang tersimpan akan muncul di sini.',
    'published' => 'Laporan yang dibagikan akan muncul di sini.',
    _ => 'Catat perkembangan siswa setelah sesi les selesai.',
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 30, 22, 38),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Image.asset(
            ReportsStyle.emptyArtwork,
            key: const ValueKey('reports-empty-artwork'),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          _title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: ReportsStyle.ink,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _description,
          textAlign: TextAlign.center,
          style: ReportsStyle.body,
        ),
        if (showAction) ...[
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('reports-add-empty'),
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: ReportsStyle.green,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(0, 46),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle, size: 23),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Tulis laporan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
