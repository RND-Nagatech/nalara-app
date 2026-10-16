import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../domain/entities/student_summary.dart';
import 'student_detail_style.dart';
import 'student_progress_chart.dart';

class StudentSummaryCards extends StatelessWidget {
  final StudentSummary summary;
  final VoidCallback onTargets;
  const StudentSummaryCards({
    super.key,
    required this.summary,
    required this.onTargets,
  });
  String _date(String value) =>
      DateFormat('d MMM', 'id_ID').format(DateTime.parse(value));
  Widget _title(String text) => Row(
    children: [
      Expanded(child: Text(text, style: StudentDetailStyle.title)),
      IconButton(
        onPressed: onTargets,
        tooltip: 'Lihat target siswa',
        icon: const Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: StudentDetailStyle.green,
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _card('student-overall-summary', [
        _title('Progress keseluruhan'),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              summary.progress == null ? '—' : '${summary.progress}%',
              key: const ValueKey('student-overall-progress'),
              style: StudentDetailStyle.title.copyWith(
                fontSize: 31,
                height: 1.2,
              ),
            ),
            Text(
              'dari ${summary.targetCount} target',
              style: StudentDetailStyle.body,
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (summary.progress == null)
          const Text(
            'Belum ada target yang dapat dihitung.',
            style: StudentDetailStyle.body,
          )
        else if (summary.trend.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'Belum ada riwayat perubahan progres.',
              style: StudentDetailStyle.body,
            ),
          )
        else ...[
          const Text(
            '7 hari terakhir · target yang masih dihitung',
            style: StudentDetailStyle.body,
          ),
          const SizedBox(height: 10),
          Semantics(
            label: summary.trend
                .map(
                  (point) => '${_date(point.date)}: ${point.progress} persen',
                )
                .join(', '),
            child: ExcludeSemantics(
              child: StudentProgressChart(points: summary.trend),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 14),
      _card('student-weekly-summary', [
        _title('Target minggu ini'),
        Text(
          '${_date(summary.weekStartDate)} – ${_date(summary.weekEndDate)}',
          style: StudentDetailStyle.body,
        ),
        const SizedBox(height: 6),
        Text(
          summary.weeklyTargetCount == 0
              ? 'Belum ada target pada minggu ini.'
              : '${summary.weeklyCompletedCount} dari ${summary.weeklyTargetCount} target selesai',
          key: const ValueKey('student-weekly-count'),
          style: StudentDetailStyle.body,
        ),
        if (summary.weeklyCompletionProgress != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: summary.weeklyCompletionProgress! / 100,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(9),
                  color: StudentDetailStyle.green,
                  backgroundColor: const Color(0xFFEDECE5),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${summary.weeklyCompletionProgress}%',
                key: const ValueKey('student-weekly-progress'),
                style: StudentDetailStyle.title.copyWith(fontSize: 23),
              ),
            ],
          ),
        ],
      ]),
    ],
  );
  Widget _card(String id, List<Widget> children) => Container(
    key: ValueKey(id),
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: NalaraCardStyle.border),
      boxShadow: const [
        BoxShadow(
          color: NalaraCardStyle.shadow,
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}
