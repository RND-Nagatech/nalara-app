import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/page.dart';
import '../domain/student_group.dart';
import '../domain/student_groups_repository.dart';

class StudentGroupsState {
  final PageResult<StudentGroup>? result;
  final bool loading;
  final String? error;
  const StudentGroupsState({this.result, this.loading = false, this.error});
}

class StudentGroupsCubit extends Cubit<StudentGroupsState> {
  final StudentGroupsRepository repository;
  String _search = '';
  int _generation = 0;
  bool _retryAppend = false;
  StudentGroupsCubit(this.repository) : super(const StudentGroupsState());

  Future<void> search(String text) {
    _search = text.trim();
    return _load(false);
  }

  Future<void> refresh() => _load(false);
  Future<void> retry() => _load(_retryAppend);
  Future<void> loadMore() async {
    if (state.loading || state.result?.hasNext != true) return;
    await _load(true);
  }

  Future<void> _load(bool append) async {
    if (isClosed) return;
    final generation = ++_generation;
    final previous = state.result;
    _retryAppend = append;
    emit(StudentGroupsState(result: append ? previous : null, loading: true));
    try {
      final result = await repository.list(
        page: append ? previous!.page + 1 : 1,
        search: _search,
      );
      if (isClosed || generation != _generation) return;
      emit(
        StudentGroupsState(
          result: append ? appendPage(previous!, result) : result,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(
        StudentGroupsState(
          result: append ? previous : null,
          error: error.toString(),
        ),
      );
    }
  }
}
