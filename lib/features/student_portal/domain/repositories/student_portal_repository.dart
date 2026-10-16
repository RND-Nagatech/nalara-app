import '../../../../shared/domain/page.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../schedules/domain/entities/session_overview.dart';
import '../../../students/domain/entities/student.dart';
import '../entities/student_portal.dart';

abstract class StudentPortalRepository {
  Future<StudentDashboard> dashboard();
  Future<Student> profile();
  Future<SessionOverview> sessionOverview(String id);
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
  });
  Future<Lesson> session(String id);
  Future<PageResult<LearningPlan>> plans({int page = 1, String? search});
  Future<LearningPlan> plan(String id);
  Future<StudentTargetDetail> target(String id);
  Future<PageResult<LessonReport>> reports({int page = 1});
  Future<LessonReport> report(String id);
  Future<PageResult<StudentNotification>> notifications({int page = 1});
  Future<void> readNotification(String id);
  Future<void> readAllNotifications();
}
