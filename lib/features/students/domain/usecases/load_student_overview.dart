import '../../../learning_goals/domain/repositories/learning_repository.dart';
import '../../../lesson_reports/domain/repositories/reports_repository.dart';
import '../../../schedules/domain/repositories/schedules_repository.dart';
import '../entities/student_overview.dart';
import '../repositories/students_repository.dart';

abstract interface class StudentOverviewLoader {
  Future<StudentOverview> call(
    String id, {
    int plansPage = 1,
    int lessonsPage = 1,
    int reportsPage = 1,
  });
}

class LoadStudentOverview implements StudentOverviewLoader {
  final StudentsRepository students;
  final LearningRepository learning;
  final SchedulesRepository schedules;
  final ReportsRepository reports;
  LoadStudentOverview(
    this.students,
    this.learning,
    this.schedules,
    this.reports,
  );

  @override
  Future<StudentOverview> call(
    String id, {
    int plansPage = 1,
    int lessonsPage = 1,
    int reportsPage = 1,
  }) async {
    // Preserve the existing repository queries and backend error messages.
    final student = await students.get(id);
    final summary = await students.summary(id);
    final plans = await learning.plans(studentId: id, page: plansPage);
    final lessons = await schedules.sessions(studentId: id, page: lessonsPage);
    final reportPage = await reports.list(studentId: id, page: reportsPage);
    final invitations = await students.invitations(id);
    return StudentOverview(
      student: student,
      summary: summary,
      plans: plans,
      lessons: lessons,
      reports: reportPage,
      invitations: invitations,
    );
  }
}
