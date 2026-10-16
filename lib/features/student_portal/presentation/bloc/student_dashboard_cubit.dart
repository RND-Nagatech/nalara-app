import '../../../../shared/state/load_cubit.dart';
import '../../domain/entities/student_portal.dart';
import '../../domain/repositories/student_portal_repository.dart';

class StudentDashboardCubit extends LoadCubit<StudentDashboard> {
  StudentDashboardCubit(StudentPortalRepository repository)
    : super(repository.dashboard);
}
