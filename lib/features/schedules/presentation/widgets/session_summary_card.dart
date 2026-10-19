import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/session_overview.dart';
import 'session_detail_style.dart';

class SessionSummaryCard extends StatelessWidget {
  final SessionOverview data;
  final VoidCallback? onStudent, onSeries;
  final bool showTeacher, showSeries;

  const SessionSummaryCard({
    super.key,
    required this.data,
    required this.onStudent,
    required this.onSeries,
    this.showTeacher = false,
    this.showSeries = true,
  });

  @override
  Widget build(BuildContext context) {
    final lesson = data.lesson;
    final zone = data.schedule.timezone;
    final start = DateTimeUtils.local(lesson.startAt, zone);
    final end = DateTimeUtils.local(lesson.endAt, zone);
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final time =
        '${DateTimeUtils.full(lesson.startAt, zone)} – '
        '${sameDay ? DateTimeUtils.time(lesson.endAt, zone) : DateTimeUtils.full(lesson.endAt, zone)}';
    return SessionSectionCard(
      children: [
        _profile(context),
        const Divider(height: 28, color: SessionDetailStyle.line),
        _detail(
          'Bidang belajar',
          lesson.subjectName.isEmpty
              ? 'Nama bidang belum tersedia'
              : lesson.subjectName,
        ),
        const SizedBox(height: 14),
        if (showTeacher) ...[
          _detail(
            'Guru',
            lesson.teacherName.isEmpty ? 'Belum tersedia' : lesson.teacherName,
          ),
          const SizedBox(height: 14),
        ],
        _detail('Waktu ($zone)', time),
        const SizedBox(height: 18),
        Wrap(
          spacing: 28,
          runSpacing: 14,
          children: [
            _status('Status', lesson.status),
            _status('Presensi', lesson.attendance),
          ],
        ),
        if (showSeries) ...[
          const Divider(height: 28, color: SessionDetailStyle.line),
          SessionActionTile(
            key: const ValueKey('session-series'),
            label: 'Detail seri jadwal',
            onPressed: onSeries,
          ),
        ],
      ],
    );
  }

  Widget _profile(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(14) > 18;
      final name = data.lesson.studentName.trim();
      final artwork = Image.asset(
        'assets/Icon/Icon lainnya.png',
        key: const ValueKey('session-artwork'),
        width: 100,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: SessionDetailStyle.sage,
                foregroundColor: SessionDetailStyle.green,
                child: Text(
                  name.isEmpty ? '–' : name.characters.first.toUpperCase(),
                  style: SessionDetailStyle.title.copyWith(
                    fontSize: 23,
                    color: SessionDetailStyle.green,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Nama siswa belum tersedia' : name,
                      style: SessionDetailStyle.title.copyWith(fontSize: 18),
                    ),
                    TextButton(
                      key: const ValueKey('session-student'),
                      onPressed: onStudent,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(48, 40),
                      ),
                      child: const Text('Lihat profil siswa'),
                    ),
                  ],
                ),
              ),
              if (!stacked) ...[const SizedBox(width: 6), artwork],
            ],
          ),
          if (stacked) Align(alignment: Alignment.centerRight, child: artwork),
        ],
      );
    },
  );

  Widget _detail(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: SessionDetailStyle.body.copyWith(fontSize: 12)),
      const SizedBox(height: 2),
      Text(
        value,
        style: SessionDetailStyle.body.copyWith(color: SessionDetailStyle.ink),
      ),
    ],
  );

  Widget _status(String label, String value) {
    final cancelled = value == 'cancelled' || value == 'absent';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SessionDetailStyle.body.copyWith(fontSize: 12)),
        const SizedBox(height: 5),
        SessionStatusBadge(
          label: statusLabel(value),
          background: cancelled
              ? SessionDetailStyle.paleRed
              : value == 'pending' || value == 'excused'
              ? SessionDetailStyle.amber
              : SessionDetailStyle.sage,
          foreground: cancelled
              ? SessionDetailStyle.red
              : value == 'pending' || value == 'excused'
              ? const Color(0xFF80632C)
              : SessionDetailStyle.green,
        ),
      ],
    );
  }
}
