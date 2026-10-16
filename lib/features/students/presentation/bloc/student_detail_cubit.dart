import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/page.dart';
import '../../domain/entities/student_overview.dart';
import '../../domain/usecases/load_student_overview.dart';

enum StudentDetailTab { summary, plans, sessions, reports, family, referral }

class StudentDetailState {
  final StudentOverview? data;
  final bool loading;
  final String? error;
  const StudentDetailState({this.data, this.loading = false, this.error});
}

class StudentDetailCubit extends Cubit<StudentDetailState> {
  final StudentOverviewLoader loadOverview;
  final String id;
  int _plansPage = 1, _lessonsPage = 1, _reportsPage = 1, _generation = 0;
  StudentDetailCubit(this.loadOverview, this.id)
    : super(const StudentDetailState());
  Future<void> refresh() {
    _plansPage = 1;
    _lessonsPage = 1;
    _reportsPage = 1;
    return load();
  }

  Future<void> load() async {
    await _load();
  }

  Future<void> _load({StudentDetailTab? appendTab}) async {
    if (isClosed) return;
    final generation = ++_generation;
    final previous = state.data;
    emit(StudentDetailState(data: state.data, loading: true));
    try {
      final data = await loadOverview(
        id,
        plansPage: _plansPage,
        lessonsPage: _lessonsPage,
        reportsPage: _reportsPage,
      );
      if (isClosed || generation != _generation) return;
      emit(
        StudentDetailState(
          data: appendTab == null || previous == null
              ? data
              : _append(previous, data, appendTab),
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(StudentDetailState(data: state.data, error: error.toString()));
    }
  }

  Future<void> changePage(StudentDetailTab tab, int page) async {
    if (page < 1 || state.loading || isClosed) return;
    switch (tab) {
      case StudentDetailTab.plans:
        _plansPage = page;
      case StudentDetailTab.sessions:
        _lessonsPage = page;
      case StudentDetailTab.reports:
        _reportsPage = page;
      default:
        return;
    }
    await load();
  }

  Future<void> loadMore(StudentDetailTab tab) async {
    final data = state.data;
    if (data == null || state.loading || isClosed) return;
    final current = switch (tab) {
      StudentDetailTab.plans => data.planPage,
      StudentDetailTab.sessions => data.lessonPage,
      StudentDetailTab.reports => data.reportPage,
      _ => null,
    };
    if (current == null || !current.hasNext) return;
    switch (tab) {
      case StudentDetailTab.plans:
        _plansPage = current.page + 1;
      case StudentDetailTab.sessions:
        _lessonsPage = current.page + 1;
      case StudentDetailTab.reports:
        _reportsPage = current.page + 1;
      default:
        return;
    }
    await _load(appendTab: tab);
  }

  StudentOverview _append(
    StudentOverview previous,
    StudentOverview next,
    StudentDetailTab tab,
  ) {
    PageResult<T> append<T>(PageResult<T> oldPage, PageResult<T> newPage) =>
        PageResult(
          items: List.unmodifiable([...oldPage.items, ...newPage.items]),
          total: newPage.total,
          page: newPage.page,
          limit: newPage.limit,
        );

    return StudentOverview(
      student: next.student,
      summary: next.summary,
      plans: tab == StudentDetailTab.plans
          ? append(previous.planPage, next.planPage)
          : next.planPage,
      lessons: tab == StudentDetailTab.sessions
          ? append(previous.lessonPage, next.lessonPage)
          : next.lessonPage,
      reports: tab == StudentDetailTab.reports
          ? append(previous.reportPage, next.reportPage)
          : next.reportPage,
      invitations: next.invitations,
      family: next.family,
    );
  }
}
