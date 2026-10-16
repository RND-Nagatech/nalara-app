import '../entities/dashboard.dart';

abstract class DashboardRepository {
  Future<TeacherDashboard> get();
}
