import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/domain/entities/student_summary.dart';
import '../../../students/domain/entities/student_overview.dart';
import '../../../progress_history/domain/entities/progress_record.dart';
import '../../../reschedule_requests/domain/entities/reschedule_request.dart';

class ParentDashboard {
  final DateTime generatedAt;
  final String timezone;
  final String parentName, parentPhone, familyName;
  final int childrenCount,
      sessionsToday,
      newReports,
      attentionTargets,
      unreadNotifications;
  final List<Student> children;
  final List<Lesson> todaySessions;
  final int? weeklyProgress;
  final List<LessonReport> latestReports;
  final List<LearningTarget> attentionTargetItems;
  const ParentDashboard({
    required this.generatedAt,
    required this.timezone,
    required this.parentName,
    required this.parentPhone,
    required this.familyName,
    required this.childrenCount,
    required this.sessionsToday,
    required this.newReports,
    required this.attentionTargets,
    required this.unreadNotifications,
    required this.children,
    required this.todaySessions,
    this.weeklyProgress,
    this.latestReports = const [],
    this.attentionTargetItems = const [],
  });
}

class ParentStudentDetail {
  final Student student;
  final List<LearningPlan> plans;
  final List<Lesson> sessions;
  final List<LessonReport> reports;
  final StudentSummary summary;
  final StudentFamilySummary family;
  const ParentStudentDetail({
    required this.student,
    required this.plans,
    required this.sessions,
    required this.reports,
    required this.summary,
    required this.family,
  });
}

class ParentTargetDetail {
  final LearningTarget target;
  final String planTitle, studentName, subjectName;
  final DateTime startAt, endAt;
  final List<ProgressRecord> history;
  const ParentTargetDetail({
    required this.target,
    required this.planTitle,
    required this.studentName,
    required this.subjectName,
    required this.startAt,
    required this.endAt,
    required this.history,
  });
}

typedef ParentRescheduleSlot = RescheduleSlot;
typedef ParentRescheduleRequest = RescheduleRequest;

class ParentNotification {
  final String id, title, body, route;
  final DateTime createdAt;
  final bool read;
  const ParentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.createdAt,
    required this.read,
  });
}
