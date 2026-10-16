import 'package:flutter/material.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_calendar.dart';
import 'agenda_style.dart';

class AgendaLessonCard extends StatelessWidget {
  final Lesson lesson;
  final String timezone;
  final VoidCallback onTap;
  const AgendaLessonCard({
    super.key,
    required this.lesson,
    required this.timezone,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final sameDay =
        ScheduleCalendar.localDate(lesson.startAt, timezone) ==
        ScheduleCalendar.localDate(lesson.endAt, timezone);
    final end = sameDay
        ? DateTimeUtils.time(lesson.endAt, timezone)
        : DateTimeUtils.full(lesson.endAt, timezone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: NalaraCardStyle.decoration(radius: 17),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.textScalerOf(context).scale(12) / 12 * 56,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateTimeUtils.time(lesson.startAt, timezone),
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: AgendaStyle.green,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          end,
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 12,
                            height: 1.4,
                            color: AgendaStyle.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.subjectName.isEmpty
                              ? 'Sesi les'
                              : lesson.subjectName,
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: AgendaStyle.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (lesson.studentName.isNotEmpty) ...[
                              lesson.studentName,
                              if (lesson.studentGrade.isNotEmpty)
                                lesson.studentGrade,
                            ] else if (lesson.teacherName.isNotEmpty)
                              'Guru: ${lesson.teacherName}',
                          ].join(' · '),
                          style: AgendaStyle.body,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${statusLabel(lesson.status)} · ${statusLabel(lesson.attendance)}',
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 11,
                            height: 1.4,
                            color: AgendaStyle.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AgendaStyle.muted,
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
