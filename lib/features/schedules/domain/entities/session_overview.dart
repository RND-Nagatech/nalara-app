import '../../../lesson_reports/domain/entities/lesson_report.dart';
import 'lesson.dart';

class SessionOverview {
  final Lesson lesson;
  final Schedule schedule;
  final List<LessonReport> reports;

  SessionOverview({
    required this.lesson,
    required this.schedule,
    required List<LessonReport> reports,
  }) : reports = List.unmodifiable(reports);
}
