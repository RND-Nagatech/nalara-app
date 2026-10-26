import 'package:flutter/material.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../schedules/presentation/widgets/lesson_timeline_card.dart';

class HomeLessonCard extends StatelessWidget {
  final Lesson lesson;
  final Lesson? nextLesson;
  final String timezone;
  // Retained for existing callers; color now follows session state, not index.
  final Color? accent;
  final VoidCallback onTap;
  const HomeLessonCard({
    super.key,
    required this.lesson,
    required this.timezone,
    this.accent,
    this.nextLesson,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => LessonTimelineCard(
    lesson: lesson,
    nextLesson: nextLesson,
    timezone: timezone,
    onTap: onTap,
    compact: true,
  );
}
