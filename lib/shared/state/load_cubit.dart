import 'package:flutter_bloc/flutter_bloc.dart';

enum LoadStatus { initial, loading, success, empty, error }

class LoadState<T> {
  final LoadStatus status;
  final T? value;
  final String? error;
  const LoadState(this.status, {this.value, this.error});
}

class LoadCubit<T> extends Cubit<LoadState<T>> {
  final Future<T> Function() loader;
  final bool Function(T)? isEmpty;
  final T Function(T previous, T next)? append;
  int _generation = 0;
  LoadCubit(this.loader, {this.isEmpty, this.append})
    : super(LoadState<T>(LoadStatus.initial));
  Future<void> load({bool append = false}) async {
    if (isClosed) return;
    final generation = ++_generation;
    emit(LoadState<T>(LoadStatus.loading, value: state.value));
    try {
      final value = await loader();
      if (!isClosed && generation == _generation) {
        final loaded = append && state.value != null && this.append != null
            ? this.append!(state.value as T, value)
            : value;
        emit(
          LoadState<T>(
            isEmpty?.call(loaded) == true
                ? LoadStatus.empty
                : LoadStatus.success,
            value: loaded,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          LoadState<T>(
            LoadStatus.error,
            value: state.value,
            error: error.toString(),
          ),
        );
      }
    }
  }
}

class SubmitState {
  final bool busy;
  final String? error;
  const SubmitState({this.busy = false, this.error});
}

class SubmitCubit extends Cubit<SubmitState> {
  SubmitCubit() : super(const SubmitState());
  Future<bool> run(Future<void> Function() operation) async {
    if (isClosed || state.busy) return false;
    emit(const SubmitState(busy: true));
    try {
      await operation();
      if (!isClosed) emit(const SubmitState());
      return true;
    } catch (error) {
      if (!isClosed) emit(SubmitState(error: error.toString()));
      return false;
    }
  }
}
