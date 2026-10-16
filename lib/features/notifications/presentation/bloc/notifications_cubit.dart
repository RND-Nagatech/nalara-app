import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/page.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsState {
  final PageResult<TeacherNotification>? result;
  final int requestedPage;
  final bool loading;
  final bool markingAll;
  final String? error, busyId, actionError, actionErrorId;

  const NotificationsState({
    this.result,
    this.requestedPage = 1,
    this.loading = false,
    this.markingAll = false,
    this.error,
    this.busyId,
    this.actionError,
    this.actionErrorId,
  });

  bool get isEmpty => !loading && error == null && result?.total == 0;
  bool get canInteract =>
      !loading &&
      !markingAll &&
      error == null &&
      busyId == null &&
      result != null;
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;
  int _request = 0;

  NotificationsCubit(this._repository) : super(const NotificationsState());

  Future<void> refresh() => _load(1);

  Future<void> reload() => _load(
    state.requestedPage,
    append: state.result != null && state.requestedPage > state.result!.page,
  );

  Future<void> goToPage(int page) async {
    final result = state.result;
    if (!state.canInteract ||
        result == null ||
        page < 1 ||
        page > (result.total / result.limit).ceil()) {
      return;
    }
    await _load(page);
  }

  Future<void> loadMore() async {
    final result = state.result;
    if (!state.canInteract || result == null || !result.hasNext) return;
    await _load(result.page + 1, append: true);
  }

  Future<void> _load(int page, {bool append = false}) async {
    if (isClosed || state.busyId != null) return;
    final request = ++_request;
    final previous = state.result;
    emit(
      NotificationsState(result: previous, requestedPage: page, loading: true),
    );
    try {
      final result = await _repository.list(page: page);
      if (isClosed || request != _request) return;
      final items = append && previous != null
          ? <TeacherNotification>[...previous.items, ...result.items]
          : result.items;
      emit(
        NotificationsState(
          result: _snapshot(result, items),
          requestedPage: result.page,
        ),
      );
    } catch (error) {
      if (isClosed || request != _request) return;
      emit(
        NotificationsState(
          result: state.result,
          requestedPage: page,
          error: error.toString(),
        ),
      );
    }
  }

  Future<bool> markRead(String id) async {
    if (isClosed || !state.canInteract) return false;
    final result = state.result!;
    final notification = result.items
        .where((item) => item.id == id)
        .firstOrNull;
    if (notification == null) return false;
    if (notification.read) return true;
    emit(
      NotificationsState(
        result: result,
        requestedPage: result.page,
        busyId: id,
      ),
    );
    try {
      await _repository.markRead(id);
      if (isClosed) return false;
      // Reflect a confirmed server write, never an optimistic read status.
      emit(
        NotificationsState(
          result: _snapshot(
            result,
            result.items.map(
              (item) => item.id == id
                  ? TeacherNotification(
                      id: item.id,
                      title: item.title,
                      body: item.body,
                      route: item.route,
                      createdAt: item.createdAt,
                      read: true,
                    )
                  : item,
            ),
          ),
          requestedPage: result.page,
        ),
      );
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          NotificationsState(
            result: result,
            requestedPage: result.page,
            actionErrorId: id,
            actionError: error.toString(),
          ),
        );
      }
      return false;
    }
  }

  Future<bool> markAllRead() async {
    if (isClosed || !state.canInteract || state.result == null) return false;
    final result = state.result!;
    if (!result.items.any((item) => !item.read)) return true;
    emit(
      NotificationsState(
        result: result,
        requestedPage: result.page,
        markingAll: true,
      ),
    );
    try {
      await _repository.markAllRead();
      if (isClosed) return false;
      emit(
        NotificationsState(
          result: _snapshot(
            result,
            result.items.map(
              (item) => TeacherNotification(
                id: item.id,
                title: item.title,
                body: item.body,
                route: item.route,
                createdAt: item.createdAt,
                read: true,
              ),
            ),
          ),
          requestedPage: result.page,
        ),
      );
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          NotificationsState(
            result: result,
            requestedPage: result.page,
            actionError: error.toString(),
          ),
        );
      }
      return false;
    }
  }

  PageResult<TeacherNotification> _snapshot(
    PageResult<TeacherNotification> source,
    Iterable<TeacherNotification> items,
  ) => PageResult(
    items: List.unmodifiable(items),
    total: source.total,
    page: source.page,
    limit: source.limit,
  );
}
