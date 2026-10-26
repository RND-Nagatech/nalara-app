import 'package:flutter/material.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_timeline_card.dart';

class AgendaLessonCard extends StatelessWidget {
  final Lesson lesson;
  final Lesson? nextLesson;
  final String timezone;
  final VoidCallback onTap;
  const AgendaLessonCard({
    super.key,
    required this.lesson,
    required this.timezone,
    required this.onTap,
    this.nextLesson,
  });
  @override
  Widget build(BuildContext context) => LessonTimelineCard(
    lesson: lesson,
    timezone: timezone,
    onTap: onTap,
    nextLesson: nextLesson,
  );
}
