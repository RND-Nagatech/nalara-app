import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../domain/entities/lesson_report.dart';
import 'reports_style.dart';

class ReportListCard extends StatelessWidget {
  final LessonReport report;
  final VoidCallback onTap;

  const ReportListCard({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final published = report.status == 'published';
    final details = [
      if (report.studentName.isNotEmpty) report.studentName,
      if (report.subjectName.isNotEmpty) report.subjectName,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: NalaraCardStyle.decoration(borderColor: ReportsStyle.line),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('report-open-${report.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusIcon(published),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.topic,
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: ReportsStyle.ink,
                          ),
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(details, style: ReportsStyle.body),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _badge(
                              statusLabel(report.status),
                              published
                                  ? ReportsStyle.green
                                  : ReportsStyle.orange,
                              published ? ReportsStyle.sage : ReportsStyle.sand,
                            ),
                            _badge(
                              statusLabel(report.visibility),
                              ReportsStyle.muted,
                              const Color(0xFFF1F0EB),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 25,
                      color: ReportsStyle.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(bool published) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: published ? ReportsStyle.sage : ReportsStyle.sand,
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: Icon(
      published ? Icons.description_rounded : Icons.edit_note_rounded,
      size: 25,
      color: published ? ReportsStyle.green : ReportsStyle.orange,
    ),
  );

  Widget _badge(String label, Color foreground, Color background) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: ReportsStyle.body.copyWith(
        fontSize: 11,
        height: 1.2,
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
