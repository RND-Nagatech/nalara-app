import '../../../../shared/state/load_cubit.dart';
import '../../domain/entities/teacher_home.dart';
import '../../domain/usecases/load_teacher_home.dart';

class DashboardCubit extends LoadCubit<TeacherHome> {
  DashboardCubit(LoadTeacherHome load) : super(load.call);
}
