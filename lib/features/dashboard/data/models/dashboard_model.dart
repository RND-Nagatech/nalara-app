import '../../../auth/data/models/teacher_model.dart';
import '../../../schedules/data/models/lesson_model.dart';
import '../../../learning_goals/data/models/learning_model.dart';
import '../../domain/entities/dashboard.dart';
import '../../../../shared/errors/app_failure.dart';

class DashboardModel {
  final Map<String, dynamic> json;
  DashboardModel(this.json);
  TeacherDashboard toEntity() {
    final rawDate = json['generatedAt'];
    final generatedAt = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (generatedAt == null) {
      throw const AppFailure(
        'Data beranda belum sesuai. Perbarui backend lalu muat ulang.',
        code: 'INVALID_RESPONSE',
      );
    }
    return TeacherDashboard(
      generatedAt: generatedAt,
      teacher: TeacherModel(
        Map<String, dynamic>.from(json['teacher']),
      ).toEntity(),
      activeStudents: json['activeStudents'],
      sessionsToday: json['sessionsToday'],
      pendingReports: json['pendingReports'],
      unreadNotifications: json['unreadNotifications'],
      todaySessions: List.unmodifiable(
        (json['todaySessions'] as List)
            .map((e) => LessonModel(Map<String, dynamic>.from(e)).toEntity())
            .toList(),
      ),
      learningPlans: List.unmodifiable(
        (json['learningPlans'] as List)
            .map((e) => PlanModel(Map<String, dynamic>.from(e)).toEntity())
            .toList(),
      ),
    );
  }
}
