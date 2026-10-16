import 'package:flutter/material.dart';
import 'reports_style.dart';

class ReportsHeader extends StatelessWidget {
  final bool loading;
  final VoidCallback onBack, onRefresh;
  final String? description;

  const ReportsHeader({
    super.key,
    required this.loading,
    required this.onBack,
    required this.onRefresh,
    this.description,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          key: const ValueKey('reports-back'),
          tooltip: 'Kembali',
          style: ReportsStyle.roundButton,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Laporan belajar', style: ReportsStyle.title),
              const SizedBox(height: 5),
              Text(
                description ?? 'Catat dan kelola perkembangan siswa.',
                style: ReportsStyle.body,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const ValueKey('reports-refresh'),
          tooltip: 'Muat ulang laporan',
          style: ReportsStyle.roundButton,
          onPressed: loading ? null : onRefresh,
          icon: loading
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ReportsStyle.green,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 23),
        ),
      ],
    ),
  );
}
