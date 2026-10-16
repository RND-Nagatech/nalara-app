import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../progress_history/domain/entities/progress_record.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../students/domain/entities/student.dart';

class StudentDashboard {
  final DateTime generatedAt;
  final String timezone;
  final Student student;
  final int? progress;
  final int sessionsToday, newReports, pendingHomework, unreadNotifications;
  final List<Lesson> todaySessions;
  final List<LearningPlan> plans;
  final List<LessonReport> recentReports;
  const StudentDashboard({
    required this.generatedAt,
    required this.timezone,
    required this.student,
    required this.sessionsToday,
    required this.progress,
    required this.newReports,
    required this.pendingHomework,
    required this.unreadNotifications,
    required this.todaySessions,
    required this.plans,
    required this.recentReports,
  });
}

class StudentTargetDetail {
  final LearningTarget target;
  final String planTitle;
  final String studentName, subjectName;
  final DateTime? planStartAt, planEndAt;
  final List<ProgressRecord> history;
  const StudentTargetDetail({
    required this.target,
    required this.planTitle,
    required this.studentName,
    required this.subjectName,
    required this.planStartAt,
    required this.planEndAt,
    required this.history,
  });
}

class StudentNotification {
  final String id, title, body, route;
  final DateTime createdAt;
  final bool read;
  const StudentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.createdAt,
    required this.read,
  });
}
