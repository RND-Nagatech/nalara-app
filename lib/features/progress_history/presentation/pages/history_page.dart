import 'package:flutter/material.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/progress_record.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryPage extends StatelessWidget {
  final String targetId;
  const HistoryPage({super.key, required this.targetId});
  @override
  Widget build(BuildContext context) => PagedListPage<ProgressRecord>(
    title: 'Riwayat progress',
    empty: 'Belum ada perubahan progress pada target ini.',
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timeline_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.before}% → ${record.after}%',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(DateTimeUtils.full(record.createdAt)),
                if (record.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(record.note),
                  ),
                Text(statusLabel(record.visibility)),
                const Text('Dicatat oleh Guru · waktu server'),
                if (record.sessionId != null)
                  const Text('Terhubung dengan sesi les'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
