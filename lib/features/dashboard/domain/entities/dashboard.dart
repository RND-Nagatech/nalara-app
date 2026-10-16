import '../../../auth/domain/entities/teacher.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';

class TeacherDashboard {
  final Teacher teacher;
  final DateTime generatedAt;
  final int activeStudents, sessionsToday, pendingReports, unreadNotifications;
  final List<Lesson> todaySessions;
  final List<LearningPlan> learningPlans;
  const TeacherDashboard({
    required this.teacher,
    required this.generatedAt,
    required this.activeStudents,
    required this.sessionsToday,
    required this.pendingReports,
    required this.unreadNotifications,
    required this.todaySessions,
    required this.learningPlans,
  });
}
