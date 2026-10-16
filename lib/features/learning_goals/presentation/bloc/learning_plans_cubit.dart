import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/page.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/repositories/learning_repository.dart';

class LearningPlansState {
  final PageResult<LearningPlan>? result;
  final bool loading;
  final String? error;
  final int requestedPage;
  const LearningPlansState({
    this.result,
    this.loading = false,
    this.error,
    this.requestedPage = 1,
  });

  bool get isEmpty =>
      !loading && error == null && result != null && result!.total == 0;
}

class LearningPlansCubit extends Cubit<LearningPlansState> {
  final Future<PageResult<LearningPlan>> Function(int page, String? studentId)
  _loadPlans;
  final String? studentId;
  int _request = 0;
  LearningPlansCubit(LearningRepository repository, {this.studentId})
    : _loadPlans = ((page, studentId) =>
          repository.plans(page: page, studentId: studentId)),
      super(const LearningPlansState());

  LearningPlansCubit.withLoader(this._loadPlans, {this.studentId})
    : super(const LearningPlansState());

  Future<void> refresh() => _load(1);
  Future<void> retry() => _load(
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
    emit(
      LearningPlansState(result: previous, loading: true, requestedPage: page),
    );
    try {
      final result = await _loadPlans(page, studentId);
      if (isClosed || request != _request) return;
      final loaded = append && previous != null
          ? PageResult<LearningPlan>(
              items: List.unmodifiable([...previous.items, ...result.items]),
              total: result.total,
              page: result.page,
              limit: result.limit,
            )
          : result;
      emit(
        LearningPlansState(
          result: PageResult(
            items: List<LearningPlan>.unmodifiable(loaded.items),
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
        LearningPlansState(
          result: state.result,
          requestedPage: page,
          error: error.toString(),
        ),
      );
    }
  }
}
