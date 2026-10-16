import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../students/domain/entities/student.dart';
import '../../domain/entities/parent_portal.dart';
import '../../domain/repositories/parent_portal_repository.dart';

class ParentDashboardState {
  final ParentDashboard? data;
  final List<Student> children;
  final String? studentId, error;
  final bool loading;
  const ParentDashboardState({
    this.data,
    this.children = const [],
    this.studentId,
    this.error,
    this.loading = false,
  });
}

class ParentDashboardCubit extends Cubit<ParentDashboardState> {
  final ParentPortalRepository repository;
  int _generation = 0;
  ParentDashboardCubit(this.repository) : super(const ParentDashboardState());

  Future<void> selectChild(String? id) async {
    if (isClosed || id == state.studentId) return;
    emit(ParentDashboardState(children: state.children, studentId: id));
    await refresh();
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final generation = ++_generation;
    final id = state.studentId;
    emit(
      ParentDashboardState(
        data: state.data,
        children: state.children,
        studentId: id,
        loading: true,
      ),
    );
    try {
      final result = await repository.dashboard(studentId: id);
      if (isClosed || generation != _generation) return;
      emit(
        ParentDashboardState(
          data: result,
          children: List.unmodifiable(result.children),
          studentId: id,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(
        ParentDashboardState(
          data: state.data,
          children: state.children,
          studentId: id,
          error: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
