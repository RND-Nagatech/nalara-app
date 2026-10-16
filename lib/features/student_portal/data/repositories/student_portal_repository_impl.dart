import '../../../../shared/domain/page.dart';
import '../../../lesson_reports/data/models/report_model.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../learning_goals/data/models/learning_model.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../schedules/data/models/lesson_model.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../schedules/domain/entities/session_overview.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/data/models/student_model.dart';
import '../../domain/entities/student_portal.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../datasources/student_portal_remote_source.dart';
import '../models/student_portal_models.dart';

class StudentPortalRepositoryImpl implements StudentPortalRepository {
  final StudentPortalRemoteSource remote;
  StudentPortalRepositoryImpl(this.remote);
  PageResult<T> page<T>(Map<String, dynamic> json, List<T> items) => PageResult(
    items: items,
    total: json['total'] as int,
    page: json['page'] as int,
    limit: json['limit'] as int,
  );
  @override
  Future<StudentDashboard> dashboard() async =>
      StudentDashboardModel(await remote.dashboard()).toEntity();
  @override
  Future<Student> profile() async {
    final json = await remote.profile();
    return StudentModel(Map<String, dynamic>.from(json['student'])).toEntity();
  }

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
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
  }) async {
    final json = await remote.sessions({
      'page': page,
      'limit': 100,
      'from': ?from?.toUtc().toIso8601String(),
      'to': ?to?.toUtc().toIso8601String(),
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
  Future<PageResult<LearningPlan>> plans({int page = 1, String? search}) async {
    final json = await remote.plans({
      'page': page,
      'limit': 100,
      'search': ?search,
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
  Future<StudentTargetDetail> target(String id) async =>
      StudentTargetDetailModel(await remote.target(id)).toEntity();
  @override
  Future<PageResult<LessonReport>> reports({int page = 1}) async {
    final json = await remote.reports({'page': page, 'limit': 100});
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
  Future<PageResult<StudentNotification>> notifications({int page = 1}) async {
    final json = await remote.notifications(page);
    return this.page(
      json,
      (json['items'] as List)
          .map(
            (row) => StudentNotificationModel(
              Map<String, dynamic>.from(row),
            ).toEntity(),
          )
          .toList(),
    );
  }

  @override
  Future<void> readNotification(String id) => remote.readNotification(id);
  @override
  Future<void> readAllNotifications() => remote.readAllNotifications();
}
