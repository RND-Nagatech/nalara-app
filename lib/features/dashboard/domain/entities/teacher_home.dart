import '../../../schedules/domain/entities/lesson.dart';
import 'dashboard.dart';

class TeacherHome {
  final TeacherDashboard overview;
  final List<Lesson> previewSessions;
  const TeacherHome({required this.overview, required this.previewSessions});
}
