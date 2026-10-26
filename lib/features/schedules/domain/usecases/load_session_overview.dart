import '../../../lesson_reports/domain/repositories/reports_repository.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../entities/session_overview.dart';
import '../repositories/schedules_repository.dart';

class LoadSessionOverview {
  final SchedulesRepository schedules;
  final ReportsRepository reports;

  LoadSessionOverview(this.schedules, this.reports);

  Future<SessionOverview> call(String id) async {
    // The session endpoint resolves student/subject names from their stable IDs.
    final lesson = await schedules.session(id);
    final schedule = await schedules.schedule(lesson.scheduleId);
    final records = <LessonReport>[];
    var pageNumber = 1;
    while (true) {
      final page = await reports.list(sessionId: id, page: pageNumber);
      records.addAll(page.items);
      if (!page.hasNext) break;
      pageNumber++;
    }
    return SessionOverview(
      lesson: lesson,
      schedule: schedule,
      reports: records,
    );
  }
}
