import '../../domain/entities/dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_source.dart';
import '../models/dashboard_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteSource remote;
  DashboardRepositoryImpl(this.remote);
  @override
  Future<TeacherDashboard> get() async =>
      DashboardModel(await remote.get()).toEntity();
}
