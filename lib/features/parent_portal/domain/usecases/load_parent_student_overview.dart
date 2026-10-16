import '../../../students/domain/entities/student_overview.dart';
import '../../../students/domain/usecases/load_student_overview.dart';
import '../repositories/parent_portal_repository.dart';

/// Supplies the shared student detail with parent-authorized server data.
class LoadParentStudentOverview implements StudentOverviewLoader {
  final ParentPortalRepository repository;
  LoadParentStudentOverview(this.repository);

  @override
  Future<StudentOverview> call(
    String id, {
    int plansPage = 1,
    int lessonsPage = 1,
    int reportsPage = 1,
  }) async {
    final detail = await repository.student(id);
    final plans = await repository.plans(studentId: id, page: plansPage);
    final sessions = await repository.sessions(
      studentId: id,
      page: lessonsPage,
    );
    final reports = await repository.reports(studentId: id, page: reportsPage);
    return StudentOverview(
      student: detail.student,
      summary: detail.summary,
      family: detail.family,
      plans: plans,
      lessons: sessions,
      reports: reports,
      invitations: const [],
    );
  }
}
