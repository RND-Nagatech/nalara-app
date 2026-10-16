import 'package:flutter/material.dart';

import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../domain/entities/lesson_report.dart';
import 'report_detail_style.dart';
import 'reports_style.dart';
import '../../../tutor_tools/presentation/tutor_tools_pages.dart';

class ReportDetailContent extends StatelessWidget {
  final LessonReport report;
  final Lesson lesson;
  final String studentName;
  final bool busy;
  final String? error;
  final bool readOnly;
  final VoidCallback? onEdit, onPublish;
  final VoidCallback onOpenSession;
  final ValueChanged<String> onOpenTarget;

  const ReportDetailContent({
    super.key,
    required this.report,
    required this.lesson,
    required this.studentName,
    required this.busy,
    required this.error,
    this.onEdit,
    this.onPublish,
    this.readOnly = false,
    required this.onOpenSession,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        key: PageStorageKey('report-detail-${report.id}'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          _intro(),
          const SizedBox(height: 18),
          _sessionSummary(),
          const SizedBox(height: 20),
          _notes(),
          const SizedBox(height: 24),
          _targets(),
          const SizedBox(height: 24),
          if (!readOnly && report.status == 'draft') ...[
            const Text(
              'Draft hanya terlihat oleh Guru. Notifikasi muncul setelah laporan dibagikan dan diterbitkan.',
              style: ReportDetailStyle.caption,
            ),
            const SizedBox(height: 6),
            const Text(
              'Laporan yang sudah terbit tidak dapat diubah.',
              style: ReportDetailStyle.caption,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    style: ReportDetailStyle.body.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: busy ? null : onPublish,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        semanticsLabel: 'Menerbitkan laporan',
                      ),
                    )
                  : const Text('Terbitkan laporan'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: busy ? null : onEdit,
              child: const Text('Edit draft'),
            ),
          ],
          if (report.publishedAt != null)
            Text(
              'Diterbitkan ${DateTimeUtils.full(report.publishedAt!)}',
              style: ReportDetailStyle.caption,
            ),
          if (!readOnly) ...[
            const SizedBox(height: 10),
            ReportPdfButton(reportId: report.id),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: busy ? null : onOpenSession,
            child: const Text('Kembali ke sesi les'),
          ),
        ],
      ),
    ),
  );

  Widget _intro() {
    final published = report.status == 'published';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: published ? ReportsStyle.sage : ReportsStyle.sand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel(report.status),
                style: ReportDetailStyle.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: published ? ReportsStyle.green : ReportsStyle.orange,
                ),
              ),
            ),
            Text(
              statusLabel(report.visibility),
              style: ReportDetailStyle.caption,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(report.topic, style: ReportDetailStyle.topic),
        ),
      ],
    );
  }

  Widget _sessionSummary() {
    final subject = report.subjectName.trim().isNotEmpty
        ? report.subjectName
        : lesson.subjectName;
    return NalaraSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Siswa', style: ReportDetailStyle.caption),
          const SizedBox(height: 4),
          Text(
            studentName,
            style: ReportDetailStyle.heading.copyWith(fontSize: 17),
          ),
          if (subject.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subject, style: ReportDetailStyle.caption),
          ],
          const Divider(height: 28, color: ReportsStyle.line),
          const Text('Waktu sesi', style: ReportDetailStyle.caption),
          const SizedBox(height: 4),
          Text(
            '${DateTimeUtils.full(lesson.startAt)} – ${DateTimeUtils.time(lesson.endAt)}',
            style: ReportDetailStyle.body,
          ),
        ],
      ),
    );
  }

  Widget _notes() {
    final sections = [
      (title: 'Ringkasan kegiatan', value: report.summary),
      if (report.observations.trim().isNotEmpty)
        (title: 'Perkembangan yang diamati', value: report.observations),
      if (report.difficulties.trim().isNotEmpty)
        (title: 'Kesulitan', value: report.difficulties),
      if (report.homework.trim().isNotEmpty)
        (title: 'Tugas / latihan lanjutan', value: report.homework),
      if (report.recommendation.trim().isNotEmpty)
        (title: 'Rekomendasi sesi berikutnya', value: report.recommendation),
    ];
    return NalaraSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < sections.length; index++) ...[
            if (index > 0) const Divider(height: 32, color: ReportsStyle.line),
            Semantics(
              header: true,
              child: Text(
                sections[index].title,
                style: ReportDetailStyle.heading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sections[index].value.trim().isEmpty
                  ? '—'
                  : sections[index].value,
              style: ReportDetailStyle.body,
            ),
          ],
        ],
      ),
    );
  }

  Widget _targets() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'Target dievaluasi',
              style: ReportDetailStyle.heading,
            ),
          ),
          if (report.targetIds.isNotEmpty)
            Text(
              '${report.targetIds.length} target',
              style: ReportDetailStyle.caption,
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (report.targetIds.isEmpty)
        const Text(
          'Belum ada target terkait.',
          style: ReportDetailStyle.caption,
        )
      else
        NalaraSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var index = 0; index < report.targetIds.length; index++) ...[
                if (index > 0)
                  const Divider(height: 1, color: ReportsStyle.line),
                InkWell(
                  key: ValueKey('report-target-${report.targetIds[index]}'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: busy
                      ? null
                      : () => onOpenTarget(report.targetIds[index]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.targetIds.length == 1
                                ? 'Lihat target belajar'
                                : 'Lihat target belajar ${index + 1}',
                            style: ReportDetailStyle.body,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 21,
                            color: ReportsStyle.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}
