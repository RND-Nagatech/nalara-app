import '../../../lesson_reports/domain/entities/lesson_report.dart';
import 'lesson.dart';

class SessionOverview {
  final Lesson lesson;
  final Schedule schedule;
  final List<LessonReport> reports;

  /// Parent-only authoritative flag; null means an older/non-parent response.
  final bool? reschedulePending;

  SessionOverview({
    required this.lesson,
    required this.schedule,
    required List<LessonReport> reports,
    this.reschedulePending,
  }) : reports = List.unmodifiable(reports);
}
