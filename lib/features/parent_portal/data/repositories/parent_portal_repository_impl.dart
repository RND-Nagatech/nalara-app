import '../../../../shared/domain/page.dart';
import '../../../lesson_reports/data/models/report_model.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../learning_goals/data/models/learning_model.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../schedules/data/models/lesson_model.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../schedules/domain/entities/session_overview.dart';
import '../../../students/data/models/student_model.dart';
import '../../../students/domain/entities/student.dart';
import '../../domain/entities/parent_portal.dart';
import '../../domain/repositories/parent_portal_repository.dart';
import '../datasources/parent_portal_remote_source.dart';
import '../models/parent_portal_models.dart';

class ParentPortalRepositoryImpl implements ParentPortalRepository {
  final ParentPortalRemoteSource remote;
  ParentPortalRepositoryImpl(this.remote);
  PageResult<T> page<T>(Map<String, dynamic> json, List<T> items) => PageResult(
    items: items,
    total: json['total'] as int,
    page: json['page'] as int,
    limit: json['limit'] as int,
  );
  @override
  Future<ParentDashboard> dashboard({String? studentId}) async =>
      ParentDashboardModel(
        await remote.dashboard(studentId: studentId),
      ).toEntity();
  @override
  Future<PageResult<Student>> students({
    int page = 1,
    String search = '',
    String? status,
  }) async {
    final json = await remote.students(page, search, status);
    return this.page(
      json,
      (json['items'] as List)
          .map((row) => StudentModel(Map<String, dynamic>.from(row)).toEntity())
          .toList(),
    );
  }

  @override
  Future<ParentStudentDetail> student(String id) async =>
      ParentStudentDetailModel(await remote.student(id)).toEntity();
  @override
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
    String? studentId,
  }) async {
    final json = await remote.sessions({
      'page': page,
      'limit': 100,
      'from': ?from?.toUtc().toIso8601String(),
      'to': ?to?.toUtc().toIso8601String(),
      'studentId': ?studentId,
    });
    return this.page(
      json,
      (json['items'] as List)
          .map((row) => LessonModel(Map<String, dynamic>.from(row)).toEntity())
          .toList(),
    );
  }

  @override
  Future<Lesson> session(String id) async =>
      LessonModel(await remote.session(id)).toEntity();
  @override
  Future<SessionOverview> sessionOverview(String id) async {
    final json = await remote.sessionOverview(id);
    return SessionOverview(
      lesson: LessonModel(Map<String, dynamic>.from(json['lesson'])).toEntity(),
      schedule: ScheduleModel(
        Map<String, dynamic>.from(json['schedule']),
      ).toEntity(),
      reports: (json['reports'] as List)
          .map((row) => ReportModel(Map<String, dynamic>.from(row)).toEntity())
          .toList(),
    );
  }

  @override
  Future<PageResult<LearningPlan>> plans({
    int page = 1,
    String? studentId,
  }) async {
    final json = await remote.plans({
      'page': page,
      'limit': 100,
      'studentId': ?studentId,
    });
    return this.page(
      json,
      (json['items'] as List)
          .map((row) => PlanModel(Map<String, dynamic>.from(row)).toEntity())
          .toList(),
    );
  }

  @override
  Future<LearningPlan> plan(String id) async =>
      PlanModel(await remote.plan(id)).toEntity();
  @override
  Future<ParentTargetDetail> target(String id) async =>
      ParentTargetDetailModel(await remote.target(id)).toEntity();
  @override
  Future<PageResult<LessonReport>> reports({
    int page = 1,
    String? studentId,
  }) async {
    final json = await remote.reports({
      'page': page,
      'limit': 100,
      'studentId': ?studentId,
    });
    return this.page(
      json,
      (json['items'] as List)
          .map((row) => ReportModel(Map<String, dynamic>.from(row)).toEntity())
          .toList(),
    );
  }

  @override
  Future<LessonReport> report(String id) async =>
      ReportModel(await remote.report(id)).toEntity();
  @override
  Future<PageResult<ParentNotification>> notifications({int page = 1}) async {
    final json = await remote.notifications(page);
    return this.page(
      json,
      (json['items'] as List)
          .map(
            (row) => ParentNotificationModel(
              Map<String, dynamic>.from(row),
            ).toEntity(),
          )
          .toList(),
    );
  }

  @override
  Future<void> markNotificationRead(String id) => remote.readNotification(id);
  @override
  Future<void> markAllNotificationsRead() => remote.readAllNotifications();
  @override
  Future<List<ParentRescheduleSlot>> availability(
    String sessionId,
    DateTime from,
    DateTime to,
  ) async {
    final json = await remote.availability(sessionId, from, to);
    return (json['slots'] as List)
        .map(
          (row) => ParentRescheduleSlotModel(
            Map<String, dynamic>.from(row),
          ).toEntity(),
        )
        .toList();
  }

  @override
  Future<void> requestReschedule(
    String sessionId,
    DateTime startAt,
    DateTime endAt,
    String reason,
  ) => remote.requestReschedule(sessionId, startAt, endAt, reason);
  @override
  Future<PageResult<ParentRescheduleRequest>> rescheduleRequests({
    int page = 1,
  }) async {
    final json = await remote.rescheduleRequests(page);
    return this.page(
      json,
      (json['items'] as List)
          .map(
            (row) => ParentRescheduleRequestModel(
              Map<String, dynamic>.from(row),
            ).toEntity(),
          )
          .toList(),
    );
  }

  @override
  Future<void> cancelRescheduleRequest(String id) =>
      remote.cancelRescheduleRequest(id);

  @override
  Future<void> respondRescheduleRequest(String id, String action) =>
      remote.respondRescheduleRequest(id, action);
}
