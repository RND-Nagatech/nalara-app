import 'package:flutter/material.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../../utils/color.dart';
import '../../domain/entities/progress_record.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryPage extends StatelessWidget {
  final String targetId;
  const HistoryPage({super.key, required this.targetId});
  @override
  Widget build(BuildContext context) => PagedListPage<ProgressRecord>(
    title: 'Riwayat progress',
    empty: 'Belum ada perubahan progress pada target ini.',
    emptyArtwork: 'assets/Empty/Empty target.png',
    load: (page) => getIt<HistoryRepository>().list(targetId, page: page),
    itemBuilder: (context, record, _) => HistoryRecordCard(record: record),
  );
}

class HistoryRecordCard extends StatelessWidget {
  final ProgressRecord record;
  const HistoryRecordCard({super.key, required this.record});
  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey(record.id),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: NalaraCardStyle.decoration(radius: 17),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${record.before}% → ${record.after}%',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: NalaraColors.green,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateTimeUtils.full(record.createdAt),
            style: const TextStyle(fontSize: 12, color: NalaraColors.muted),
          ),
          if (record.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(record.note),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(statusLabel(record.visibility)),
              const Text('Dicatat oleh Guru'),
            ],
          ),
          if (record.sessionId != null) const Text('Terhubung dengan sesi les'),
        ],
      ),
    ),
  );
}
