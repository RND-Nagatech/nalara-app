import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/page.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subjects_repository.dart';

class SubjectsState {
  final PageResult<Subject>? result;
  final bool loading;
  final String? error;
  final int requestedPage;

  const SubjectsState({
    this.result,
    this.loading = false,
    this.error,
    this.requestedPage = 1,
  });

  bool get isEmpty =>
      !loading && error == null && result != null && result!.total == 0;
}

class SubjectsCubit extends Cubit<SubjectsState> {
  final SubjectsRepository _repository;
  int _request = 0;

  SubjectsCubit(this._repository) : super(const SubjectsState());

  Future<void> refresh() => _load(1);
  Future<void> reload() => _load(
    state.requestedPage,
    append: state.result != null && state.requestedPage > state.result!.page,
  );

  Future<void> goToPage(int page) async {
    if (state.loading || page < 1) return;
    await _load(page);
  }

  Future<void> loadMore() async {
    final result = state.result;
    if (state.loading || result == null || !result.hasNext) return;
    await _load(result.page + 1, append: true);
  }

  Future<void> _load(int page, {bool append = false}) async {
    if (isClosed) return;
    final request = ++_request;
    final previous = state.result;
    emit(SubjectsState(result: previous, loading: true, requestedPage: page));
    try {
      final result = await _repository.list(page: page);
      if (isClosed || request != _request) return;
      final loaded = append && previous != null
          ? PageResult<Subject>(
              items: List.unmodifiable([...previous.items, ...result.items]),
              total: result.total,
              page: result.page,
              limit: result.limit,
            )
          : result;
      emit(
        SubjectsState(
          result: PageResult(
            items: List<Subject>.unmodifiable(loaded.items),
            total: loaded.total,
            page: loaded.page,
            limit: loaded.limit,
          ),
          requestedPage: loaded.page,
        ),
      );
    } catch (error) {
      if (isClosed || request != _request) return;
      emit(
        SubjectsState(
          result: state.result,
          requestedPage: page,
          error: error.toString(),
        ),
      );
    }
  }
}
