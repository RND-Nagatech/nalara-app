import '../../../../shared/domain/page.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../schedules/domain/entities/session_overview.dart';
import '../../../students/domain/entities/student.dart';
import '../entities/parent_portal.dart';

abstract class ParentPortalRepository {
  Future<ParentDashboard> dashboard({String? studentId});
  Future<PageResult<Student>> students({
    int page = 1,
    String search = '',
    String? status,
  });
  Future<ParentStudentDetail> student(String id);
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
    String? studentId,
  });
  Future<Lesson> session(String id);
  Future<SessionOverview> sessionOverview(String id);
  Future<PageResult<LearningPlan>> plans({int page = 1, String? studentId});
  Future<LearningPlan> plan(String id);
  Future<ParentTargetDetail> target(String id);
  Future<PageResult<LessonReport>> reports({int page = 1, String? studentId});
  Future<LessonReport> report(String id);
  Future<PageResult<ParentNotification>> notifications({int page = 1});
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead();
  Future<List<ParentRescheduleSlot>> availability(
    String sessionId,
    DateTime from,
    DateTime to,
  );
  Future<void> requestReschedule(
    String sessionId,
    DateTime startAt,
    DateTime endAt,
    String reason,
  );
  Future<PageResult<ParentRescheduleRequest>> rescheduleRequests({
    int page = 1,
  });
  Future<void> cancelRescheduleRequest(String id);
  Future<void> respondRescheduleRequest(String id, String action);
}
