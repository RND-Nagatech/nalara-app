import '../../../lesson_reports/data/models/report_model.dart';
import '../../../learning_goals/data/models/learning_model.dart';
import '../../../progress_history/data/models/history_model.dart';
import '../../../schedules/data/models/lesson_model.dart';
import '../../../students/data/models/student_model.dart';
import '../../domain/entities/student_portal.dart';

class StudentDashboardModel {
  final Map<String, dynamic> json;
  StudentDashboardModel(this.json);
  StudentDashboard toEntity() => StudentDashboard(
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    timezone: json['timezone'] as String? ?? 'Asia/Jakarta',
    student: StudentModel(
      Map<String, dynamic>.from(json['student']),
    ).toEntity(),
    sessionsToday: json['sessionsToday'] as int? ?? 0,
    progress: json['progress'] as int?,
    newReports: json['newReports'] as int? ?? 0,
    pendingHomework: json['pendingHomework'] as int? ?? 0,
    unreadNotifications: json['unreadNotifications'] as int? ?? 0,
    todaySessions: ((json['todaySessions'] as List?) ?? [])
        .map((row) => LessonModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
    plans: ((json['plans'] as List?) ?? [])
        .map((row) => PlanModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
    recentReports: ((json['recentReports'] as List?) ?? [])
        .map((row) => ReportModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
  );
}

class StudentTargetDetailModel {
  final Map<String, dynamic> json;
  StudentTargetDetailModel(this.json);
  StudentTargetDetail toEntity() {
    final plan = json['plan'] as Map?;
    return StudentTargetDetail(
      target: TargetModel(json).toEntity(),
      planTitle: plan?['_id'] == null ? '' : plan?['title'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      planStartAt: plan?['startAt'] == null
          ? null
          : DateTime.parse(plan!['startAt'] as String),
      planEndAt: plan?['endAt'] == null
          ? null
          : DateTime.parse(plan!['endAt'] as String),
      history: ((json['history'] as List?) ?? [])
          .map(
            (row) => HistoryModel({
              'actorId': '',
              ...Map<String, dynamic>.from(row),
            }).toEntity(),
          )
          .toList(),
    );
  }
}

class StudentNotificationModel {
  final Map<String, dynamic> json;
  StudentNotificationModel(this.json);
  StudentNotification toEntity() => StudentNotification(
    id: json['_id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    route: json['route'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    read: json['readAt'] != null,
  );
}
