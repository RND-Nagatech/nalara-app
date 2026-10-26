import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_calendar.dart';
import 'agenda_style.dart';

class AttendanceLessonCard extends StatelessWidget {
  final Lesson lesson;
  final String timezone;
  final VoidCallback onTap;

  const AttendanceLessonCard({
    super.key,
    required this.lesson,
    required this.timezone,
    required this.onTap,
  });

  static const _muted = Color(0xFF626D66);
  static const _body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12,
    height: 1.5,
    color: _muted,
  );

  @override
  Widget build(BuildContext context) {
    final sameDay =
        ScheduleCalendar.localDate(lesson.startAt, timezone) ==
        ScheduleCalendar.localDate(lesson.endAt, timezone);
    final end = sameDay
        ? DateTimeUtils.time(lesson.endAt, timezone)
        : DateTimeUtils.full(lesson.endAt, timezone);
    final (background, foreground) = switch (lesson.attendance) {
      'present' => (const Color(0xFFEAF2E9), AgendaStyle.green),
      'pending' ||
      'excused' => (const Color(0xFFFFF3DC), const Color(0xFF806127)),
      'absent' ||
      'cancelled' => (const Color(0xFFFFEEEB), const Color(0xFFAE3E34)),
      _ => (const Color(0xFFF0F0ED), _muted),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: NalaraCardStyle.decoration(radius: 19),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('attendance-session-${lesson.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          lesson.studentName.isEmpty
                              ? 'Sesi belajar'
                              : lesson.studentName,
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: AgendaStyle.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: _muted,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                  if (lesson.subjectName.isNotEmpty ||
                      lesson.studentGrade.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        lesson.subjectName,
                        lesson.studentGrade,
                      ].where((value) => value.isNotEmpty).join(' · '),
                      style: _body,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '${DateTimeUtils.time(lesson.startAt, timezone)} – $end',
                    style: _body.copyWith(
                      color: AgendaStyle.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Container(
                        key: ValueKey('attendance-status-${lesson.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          lesson.isGroup
                              ? lesson.attendanceSummary
                              : statusLabel(lesson.attendance),
                          style: _body.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Sesi ${statusLabel(lesson.status).toLowerCase()}',
                        style: _body,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
