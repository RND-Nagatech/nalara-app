import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../../utils/color.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_timing.dart';
import '../../domain/entities/lesson_timeline_segment.dart';
import '../../domain/entities/schedule_calendar.dart';
import 'lesson_clock.dart';
import 'lesson_status.dart';
import 'lesson_timeline_connector.dart';

/// Agenda and compact Home share status semantics and one visual language.
class LessonTimelineCard extends StatelessWidget {
  final Lesson lesson;
  final Lesson? nextLesson;
  final String timezone;
  final VoidCallback onTap;
  final bool compact;
  const LessonTimelineCard({
    super.key,
    required this.lesson,
    required this.timezone,
    required this.onTap,
    this.compact = false,
    this.nextLesson,
  });

  @override
  Widget build(BuildContext context) => LessonClockBuilder(
    builder: (context, now) {
      final timing = LessonTiming.at(lesson, now);
      final next = nextLesson;
      final segment =
          next != null &&
              ScheduleCalendar.localDate(lesson.startAt, timezone) ==
                  ScheduleCalendar.localDate(next.startAt, timezone)
          ? LessonTimelineSegment.between(lesson, next)
          : null;
      final markerTop = compact ? 14.0 : 16.0;
      final timeWidth = math.max(
        48.0,
        MediaQuery.textScalerOf(context).scale(12) * 4.3,
      );
      final sameDay =
          ScheduleCalendar.localDate(lesson.startAt, timezone) ==
          ScheduleCalendar.localDate(lesson.endAt, timezone);
      final end = sameDay
          ? DateTimeUtils.time(lesson.endAt, timezone)
          : DateTimeUtils.full(lesson.endAt, timezone);
      final surface = timing.active
          ? NalaraColors.sessionActiveSurface
          : NalaraColors.surface;
      final border = timing.active
          ? NalaraColors.sessionActiveBorder
          : NalaraCardStyle.border;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (segment != null)
            PositionedDirectional(
              start: timeWidth + 11,
              top: markerTop + 22,
              bottom: -(markerTop - 4),
              width: 2,
              child: LessonTimelineConnector(segment: segment, now: now),
            ),
          PositionedDirectional(
            start: 0,
            top: compact ? 13 : 15,
            width: timeWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateTimeUtils.time(lesson.startAt, timezone),
                  style: timing.active
                      ? const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 11,
                          height: 1.4,
                          color: NalaraColors.muted,
                        )
                      : const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: NalaraColors.ink,
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  end,
                  style: timing.active
                      ? const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: NalaraColors.ink,
                        )
                      : const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 11,
                          height: 1.4,
                          color: NalaraColors.muted,
                        ),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            start: timeWidth + 3,
            top: markerTop,
            child: LessonStatusDot(timing: timing),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: timeWidth + 26,
              bottom: compact ? 10 : 14,
            ),
            child: Container(
              constraints: BoxConstraints(
                minHeight: math.max(
                  compact ? 100 : 112,
                  MediaQuery.textScalerOf(context).scale(12) *
                      (sameDay ? 5 : 9),
                ),
              ),
              decoration: NalaraCardStyle.decoration(
                radius: 17,
                color: surface,
                borderColor: border,
              ),
              child: Material(
                color: surface,
                borderRadius: BorderRadius.circular(17),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 12 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                lesson.subjectName.isEmpty
                                    ? 'Sesi les'
                                    : lesson.subjectName,
                                style: const TextStyle(
                                  fontFamily: 'NalaraInter',
                                  fontSize: 14,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                  color: NalaraColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: NalaraColors.muted,
                            ),
                          ],
                        ),
                        if (lesson.studentName.isNotEmpty ||
                            lesson.teacherName.isNotEmpty) ...[
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
                            style: const TextStyle(
                              fontFamily: 'NalaraInter',
                              fontSize: 12,
                              height: 1.5,
                              color: NalaraColors.muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 7),
                        LessonStatus(timing: timing, showDot: false),
                        if (lesson.isGroup ||
                            (lesson.attendance != 'pending' &&
                                lesson.status != 'cancelled')) ...[
                          const SizedBox(height: 4),
                          Text(
                            lesson.isGroup
                                ? lesson.attendanceSummary
                                : 'Presensi: ${statusLabel(lesson.attendance)}',
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: NalaraColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
