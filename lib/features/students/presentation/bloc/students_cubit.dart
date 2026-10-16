import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/page.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_filter.dart';
import '../../domain/usecases/load_students.dart';

class StudentListState {
  final PageResult<Student>? data;
  final bool loading;
  final String? error;
  final int requestedPage;
  final bool appending;
  const StudentListState({
    this.data,
    this.loading = false,
    this.error,
    this.requestedPage = 1,
    this.appending = false,
  });
}

class StudentsState {
  final StudentFilter selected;
  final String search;
  final Map<StudentFilter, StudentListState> lists;
  const StudentsState({
    this.selected = StudentFilter.active,
    this.search = '',
    this.lists = const {},
  });
  StudentListState forFilter(StudentFilter filter) =>
      lists[filter] ?? const StudentListState();
  StudentListState get current => forFilter(selected);
}

class StudentsCubit extends Cubit<StudentsState> {
  final LoadStudents _loadStudents;
  final Duration debounce;
  Timer? _searchTimer;
  int _epoch = 0, _sequence = 0;
  final _requests = <StudentFilter, int>{};
  StudentsCubit(
    this._loadStudents, {
    this.debounce = const Duration(milliseconds: 350),
  }) : super(const StudentsState());

  Future<void> select(StudentFilter filter) async {
    if (isClosed) return;
    final changing = filter != state.selected;
    if (changing) {
      emit(
        StudentsState(
          selected: filter,
          search: state.search,
          lists: state.lists,
        ),
      );
    }
    if (_searchTimer?.isActive == true) {
      if (!changing) return;
      _searchTimer?.cancel();
    }
    final current = state.forFilter(filter);
    if (!current.loading && (current.data == null || current.error != null)) {
      await _load(filter);
    }
  }

  void search(String value, {bool immediate = false}) {
    if (isClosed) return;
    final query = value.trim();
    if (query == state.search && !immediate) return;
    _searchTimer?.cancel();
    _epoch++;
    _requests.clear();
    emit(StudentsState(selected: state.selected, search: query));
    if (immediate) {
      unawaited(_load(state.selected));
    } else {
      _searchTimer = Timer(debounce, () => unawaited(_load(state.selected)));
    }
  }

  /// Mutations/refresh invalidate every filter, not just the visible tab.
  Future<void> refresh() async {
    if (isClosed) return;
    _searchTimer?.cancel();
    _epoch++;
    _requests.clear();
    final filter = state.selected;
    final previous = state.current.data;
    emit(
      StudentsState(
        selected: filter,
        search: state.search,
        lists: Map.unmodifiable({filter: StudentListState(data: previous)}),
      ),
    );
    await _load(filter);
  }

  Future<void> page(int page, {StudentFilter? filter}) async {
    final target = filter ?? state.selected;
    if (isClosed || state.forFilter(target).loading || page < 1) return;
    await _load(target, page: page);
  }

  Future<void> loadMore({StudentFilter? filter}) async {
    final target = filter ?? state.selected;
    final current = state.forFilter(target);
    final data = current.data;
    if (isClosed || current.loading || data == null || !data.hasNext) return;
    await _load(target, page: data.page + 1, append: true);
  }

  Future<void> retry(StudentFilter filter) => _load(
    filter,
    page: state.forFilter(filter).requestedPage,
    append: state.forFilter(filter).appending,
  );

  Future<void> _load(
    StudentFilter filter, {
    int page = 1,
    bool append = false,
  }) async {
    if (isClosed || state.forFilter(filter).loading) return;
    final epoch = _epoch, ticket = ++_sequence, query = state.search;
    _requests[filter] = ticket;
    final previous = state.forFilter(filter).data;
    _set(
      filter,
      StudentListState(
        data: previous,
        loading: true,
        requestedPage: page,
        appending: append,
      ),
    );
    bool current() =>
        !isClosed && epoch == _epoch && _requests[filter] == ticket;
    try {
      final data = await _loadStudents(
        filter: filter,
        search: query,
        page: page,
      );
      if (current()) {
        final combined = append && previous != null
            ? PageResult<Student>(
                items: List.unmodifiable([...previous.items, ...data.items]),
                total: data.total,
                page: data.page,
                limit: data.limit,
              )
            : data;
        _set(
          filter,
          StudentListState(data: combined, requestedPage: combined.page),
        );
      }
    } catch (error) {
      if (current()) {
        _set(
          filter,
          StudentListState(
            data: previous,
            error: error.toString(),
            requestedPage: page,
            appending: append,
          ),
        );
      }
    }
  }

  void _set(StudentFilter filter, StudentListState value) => emit(
    StudentsState(
      selected: state.selected,
      search: state.search,
      lists: Map.unmodifiable({...state.lists, filter: value}),
    ),
  );

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    _epoch++;
    return super.close();
  }
}
