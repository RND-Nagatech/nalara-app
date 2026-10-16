import '../../../lesson_reports/domain/repositories/reports_repository.dart';
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
    final page = await reports.list(sessionId: id);
    return SessionOverview(
      lesson: lesson,
      schedule: schedule,
      reports: page.items,
    );
  }
}
