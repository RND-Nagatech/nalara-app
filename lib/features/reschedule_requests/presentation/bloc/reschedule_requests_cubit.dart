import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/page.dart';
import '../../domain/entities/reschedule_request.dart';

typedef RescheduleRequestsLoader =
    Future<PageResult<RescheduleRequest>> Function(int page);

class RescheduleRequestsState {
  final PageResult<RescheduleRequest>? data;
  final bool loading;
  final String? loadError, actionError, activeRequestId;
  final int requestedPage;

  const RescheduleRequestsState({
    this.data,
    this.loading = false,
    this.loadError,
    this.actionError,
    this.activeRequestId,
    this.requestedPage = 1,
  });

  bool get busy => loading || activeRequestId != null;
  bool get canAct => data != null && !busy && loadError == null;
}

class RescheduleRequestsCubit extends Cubit<RescheduleRequestsState> {
  final RescheduleRequestsLoader _load;
  int _generation = 0, _actionGeneration = 0;

  RescheduleRequestsCubit(this._load) : super(const RescheduleRequestsState());

  Future<void> refresh() async {
    if (!isClosed && state.activeRequestId == null) await _fetch();
  }

  Future<void> loadMore() async {
    final data = state.data;
    if (isClosed || state.busy || data == null || !data.hasNext) return;
    await _fetch(page: data.page + 1, append: true);
  }

  Future<void> retry() async {
    if (isClosed || state.busy) return;
    await _fetch(
      page: state.requestedPage,
      append: state.requestedPage > 1 && state.data != null,
    );
  }

  Future<void> _fetch({int page = 1, bool append = false}) async {
    if (isClosed) return;
    final generation = ++_generation;
    final previous = state.data;
    emit(
      RescheduleRequestsState(
        data: previous,
        loading: true,
        requestedPage: page,
      ),
    );
    try {
      final result = await _load(page);
      if (isClosed || generation != _generation) return;
      final items = append && previous != null
          ? <String, RescheduleRequest>{
              for (final item in previous.items) item.id: item,
              for (final item in result.items) item.id: item,
            }.values
          : result.items;
      emit(
        RescheduleRequestsState(
          data: PageResult(
            items: List.unmodifiable(items),
            total: result.total,
            page: result.page,
            limit: result.limit,
          ),
          requestedPage: result.page,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(
        RescheduleRequestsState(
          data: previous,
          loadError: error.toString(),
          requestedPage: page,
        ),
      );
    }
  }

  /// Locks the list during confirmations and dialogs as well as API writes.
  /// A false result means the user cancelled without submitting a change.
  Future<bool> perform(
    String requestId,
    Future<bool> Function() operation,
  ) async {
    if (isClosed || !state.canAct) return false;
    final generation = ++_actionGeneration;
    final previous = state.data;
    emit(
      RescheduleRequestsState(
        data: previous,
        activeRequestId: requestId,
        requestedPage: state.requestedPage,
      ),
    );
    try {
      final changed = await operation();
      if (isClosed || generation != _actionGeneration) return false;
      emit(
        RescheduleRequestsState(
          data: previous,
          requestedPage: state.requestedPage,
        ),
      );
      // Only server reads replace a status; a failed reload keeps rows visible
      // but disables actions until retry resolves their authoritative state.
      if (changed) await _fetch();
      return changed;
    } catch (error) {
      if (isClosed || generation != _actionGeneration) return false;
      emit(
        RescheduleRequestsState(
          data: previous,
          actionError: error.toString(),
          requestedPage: state.requestedPage,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _generation++;
    _actionGeneration++;
    return super.close();
  }
}
