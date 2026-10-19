import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/nalara_empty_state.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import 'session_detail_style.dart';

class SessionAttendanceCard extends StatefulWidget {
  final String attendance;
  final bool busy;
  final bool readOnly;
  final ValueChanged<String>? onSave;

  const SessionAttendanceCard({
    super.key,
    required this.attendance,
    required this.busy,
    required this.onSave,
    this.readOnly = false,
  });

  @override
  State<SessionAttendanceCard> createState() => _SessionAttendanceCardState();
}

class _SessionAttendanceCardState extends State<SessionAttendanceCard> {
  late String _selected = _initialValue;
  String get _initialValue =>
      widget.attendance == 'pending' ? 'present' : widget.attendance;

  @override
  void didUpdateWidget(covariant SessionAttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendance != widget.attendance) _selected = _initialValue;
  }

  @override
  Widget build(BuildContext context) => widget.readOnly
      ? SessionSectionCard(
          title: 'Presensi',
          description: widget.attendance == 'pending'
              ? 'Presensi belum dicatat oleh Guru.'
              : 'Presensi sudah dicatat oleh Guru.',
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SessionStatusBadge(
                key: const ValueKey('session-attendance-status'),
                label: statusLabel(widget.attendance),
                background: switch (widget.attendance) {
                  'absent' || 'cancelled' => SessionDetailStyle.paleRed,
                  'pending' || 'excused' => SessionDetailStyle.amber,
                  _ => SessionDetailStyle.sage,
                },
                foreground: switch (widget.attendance) {
                  'absent' || 'cancelled' => SessionDetailStyle.red,
                  'pending' || 'excused' => const Color(0xFF80632C),
                  _ => SessionDetailStyle.green,
                },
              ),
            ),
          ],
        )
      : SessionSectionCard(
          title: 'Catat presensi',
          description: widget.attendance == 'pending'
              ? 'Pilih status kehadiran siswa pada sesi ini.'
              : 'Presensi sudah disimpan dan dikunci.',
          children: [
            if (widget.attendance != 'pending')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: SessionDetailStyle.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status ${statusLabel(widget.attendance)} tidak dapat diubah lagi.',
                        style: SessionDetailStyle.body,
                      ),
                    ),
                  ],
                ),
              ),
            NalaraDropdown<String>(
              key: const ValueKey('session-attendance'),
              value: _selected,
              enabled:
                  widget.attendance == 'pending' &&
                  !widget.busy &&
                  widget.onSave != null,
              menuTitle: 'Pilih presensi',
              decoration: const InputDecoration(labelText: 'Presensi'),
              options: ['present', 'excused', 'absent', 'cancelled']
                  .map(
                    (value) => NalaraDropdownOption(
                      value: value,
                      label: statusLabel(value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selected = value!),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('session-save-attendance'),
              onPressed:
                  widget.attendance != 'pending' ||
                      widget.busy ||
                      widget.onSave == null
                  ? null
                  : () => widget.onSave!(_selected),
              child: widget.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan presensi'),
            ),
          ],
        );
}

class SessionReportsCard extends StatelessWidget {
  final List<LessonReport> reports;
  final bool cancelled;
  final bool readOnly;
  final VoidCallback? onCreate;
  final ValueChanged<LessonReport>? onOpen;

  const SessionReportsCard({
    super.key,
    required this.reports,
    required this.cancelled,
    required this.onCreate,
    required this.onOpen,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) => reports.isEmpty
      ? NalaraEmptyState(
          imagePath: 'assets/Icon/Icon laporan belum selesai.png',
          title: 'Laporan sesi',
          message: readOnly
              ? 'Belum ada laporan yang dibagikan untuk sesi ini.'
              : cancelled
              ? 'Belum ada laporan untuk sesi yang dibatalkan ini.'
              : 'Tulis ringkasan materi, catatan, dan perkembangan siswa.',
          action: !readOnly && !cancelled
              ? FilledButton(
                  key: const ValueKey('session-create-report'),
                  onPressed: onCreate,
                  child: const Text('Tulis laporan sesi'),
                )
              : null,
        )
      : SessionSectionCard(
          title: 'Laporan sesi',
          description: readOnly
              ? 'Laporan belajar yang dibagikan oleh Guru untuk sesi ini.'
              : 'Tulis ringkasan materi, catatan, dan perkembangan siswa.',
          children: [
            for (final report in reports)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SessionActionTile(
                  key: ValueKey('session-report-${report.id}'),
                  label: report.topic,
                  description: statusLabel(report.status),
                  onPressed: onOpen == null ? null : () => onOpen!(report),
                ),
              ),
          ],
        );
}
