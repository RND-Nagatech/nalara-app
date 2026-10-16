import '../../../lesson_reports/data/models/report_model.dart';
import '../../../learning_goals/data/models/learning_model.dart';
import '../../../schedules/data/models/lesson_model.dart';
import '../../../students/data/models/student_model.dart';
import '../../../students/data/models/student_summary_model.dart';
import '../../../students/domain/entities/student_overview.dart';
import '../../../progress_history/data/models/history_model.dart';
import '../../../reschedule_requests/data/models/reschedule_request_model.dart';
import '../../domain/entities/parent_portal.dart';

class ParentDashboardModel {
  final Map<String, dynamic> json;
  ParentDashboardModel(this.json);
  ParentDashboard toEntity() => ParentDashboard(
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    timezone: json['timezone'] as String? ?? 'Asia/Jakarta',
    parentName: (json['parent'] as Map)['name'] as String? ?? '',
    parentPhone: (json['parent'] as Map)['phone'] as String? ?? '',
    familyName: (json['parent'] as Map)['familyName'] as String? ?? '',
    childrenCount: json['childrenCount'] as int? ?? 0,
    sessionsToday: json['sessionsToday'] as int? ?? 0,
    newReports: json['newReports'] as int? ?? 0,
    attentionTargets: json['attentionTargets'] as int? ?? 0,
    unreadNotifications: json['unreadNotifications'] as int? ?? 0,
    weeklyProgress: json['weeklyProgress'] as int?,
    latestReports: ((json['latestReports'] as List?) ?? [])
        .map((row) => ReportModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
    attentionTargetItems: ((json['attentionTargetItems'] as List?) ?? [])
        .map((row) => TargetModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
    children: ((json['children'] as List?) ?? [])
        .map((row) => StudentModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
    todaySessions: ((json['todaySessions'] as List?) ?? [])
        .map((row) => LessonModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
  );
}

class ParentStudentDetailModel {
  final Map<String, dynamic> json;
  ParentStudentDetailModel(this.json);
  ParentStudentDetail toEntity() => ParentStudentDetail(
    summary: StudentSummaryModel(
      Map<String, dynamic>.from(json['summary']),
    ).toEntity(),
    family: StudentFamilySummary(
      id: (json['family']['id'] ?? json['family']['_id']) as String,
      name: json['family']['name'] as String? ?? '',
      parentName: json['family']['parentName'] as String? ?? '',
      parentPhone: json['family']['parentPhone'] as String? ?? '',
    ),
    student: StudentModel(
      Map<String, dynamic>.from(json['student']),
    ).toEntity(),
    plans: ((json['plans'] as List?) ?? [])
        .map((row) => PlanModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
    sessions: ((json['sessions'] as List?) ?? [])
        .map((row) => LessonModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
    reports: ((json['reports'] as List?) ?? [])
        .map((row) => ReportModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
  );
}

class ParentTargetDetailModel {
  final Map<String, dynamic> json;
  ParentTargetDetailModel(this.json);
  ParentTargetDetail toEntity() => ParentTargetDetail(
    target: TargetModel(Map<String, dynamic>.from(json['target'])).toEntity(),
    planTitle: json['planTitle'] as String? ?? '',
    studentName: json['studentName'] as String? ?? '',
    subjectName: json['subjectName'] as String? ?? '',
    startAt: DateTime.parse(json['startAt'] as String),
    endAt: DateTime.parse(json['endAt'] as String),
    history: (json['history'] as List)
        .map(
          (row) => HistoryModel({
            ...Map<String, dynamic>.from(row),
            'actorId': '',
          }).toEntity(),
        )
        .toList(),
  );
}

class ParentRescheduleSlotModel {
  final Map<String, dynamic> json;
  ParentRescheduleSlotModel(this.json);
  ParentRescheduleSlot toEntity() => RescheduleSlotModel(json).toEntity();
}

class ParentRescheduleRequestModel {
  final Map<String, dynamic> json;
  ParentRescheduleRequestModel(this.json);
  ParentRescheduleRequest toEntity() => RescheduleRequestModel(json).toEntity();
}

class ParentNotificationModel {
  final Map<String, dynamic> json;
  ParentNotificationModel(this.json);
  ParentNotification toEntity() => ParentNotification(
    id: json['_id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    route: json['route'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    read: json['readAt'] != null,
  );
}
