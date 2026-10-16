import '../../../learning_goals/domain/entities/plan_overview.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../repositories/student_portal_repository.dart';

/// All reads use the authenticated student repository, never teacher catalogs.
class LoadStudentDetails {
  final StudentPortalRepository repository;
  const LoadStudentDetails(this.repository);

  Future<PlanOverview> plan(String id) async {
    final plan = await repository.plan(id);
    final student = await repository.profile();
    return PlanOverview(plan: plan, student: student);
  }

  Future<({LessonReport report, Lesson lesson, String studentName})> report(
    String id,
  ) async {
    final report = await repository.report(id);
    final lesson = await repository.session(report.sessionId);
    return (report: report, lesson: lesson, studentName: lesson.studentName);
  }
}
