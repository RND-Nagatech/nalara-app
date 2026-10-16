import '../entities/teacher_home.dart';
import '../repositories/dashboard_repository.dart';

class LoadTeacherHome {
  final DashboardRepository repository;
  LoadTeacherHome(this.repository);
  Future<TeacherHome> call() async {
    final overview = await repository.get();
    final ordered = [...overview.todaySessions]
      ..sort((left, right) {
        final byTime = left.startAt.compareTo(right.startAt);
        return byTime == 0 ? left.id.compareTo(right.id) : byTime;
      });
    return TeacherHome(
      overview: overview,
      previewSessions: List.unmodifiable(ordered.take(3)),
    );
  }
}
