import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../schedules/domain/entities/lesson.dart';
import 'home_style.dart';

class HomeLessonCard extends StatelessWidget {
  final Lesson lesson;
  final String timezone;
  final Color accent;
  final VoidCallback onTap;
  const HomeLessonCard({
    super.key,
    required this.lesson,
    required this.timezone,
    required this.accent,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final start = DateTimeUtils.time(
      lesson.startAt,
      timezone,
    ).replaceAll(':', '.');
    final end = DateTimeUtils.time(lesson.endAt, timezone).replaceAll(':', '.');
    const startStyle = TextStyle(
      fontFamily: 'NalaraInter',
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: HomeStyle.ink,
    );
    final timeWidth = math.max(
      53.0,
      math.max(
        HomeStyle.textWidth(context, start, startStyle),
        HomeStyle.textWidth(context, end, HomeStyle.caption),
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(0, 14, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accent, accent.withValues(alpha: .12)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: timeWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(start, style: startStyle),
                        const SizedBox(height: 6),
                        Text(end, style: HomeStyle.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.subjectName,
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: HomeStyle.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (lesson.studentName.isNotEmpty ||
                            lesson.studentGrade.isNotEmpty ||
                            lesson.teacherName.isNotEmpty)
                          Text(
                            [
                              if (lesson.studentName.isNotEmpty) ...[
                                lesson.studentName,
                                if (lesson.studentGrade.isNotEmpty)
                                  lesson.studentGrade,
                              ] else if (lesson.teacherName.isNotEmpty)
                                'Guru: ${lesson.teacherName}',
                            ].join(' · '),
                            style: HomeStyle.caption,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: HomeStyle.ink,
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
