import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/avatar.dart';

class AvatarPickerState {
  final bool loading, saving;
  final List<ProfileAvatar> options;
  final String? selected, error;
  final AvatarSelection? saved;
  const AvatarPickerState({
    this.loading = false,
    this.saving = false,
    this.options = const [],
    this.selected,
    this.error,
    this.saved,
  });
}

class AvatarPickerCubit extends Cubit<AvatarPickerState> {
  final AvatarsRepository repository;
  AvatarPickerCubit(this.repository, String? initial)
    : super(AvatarPickerState(selected: initial));
  Future<void> load() async {
    if (state.loading || state.saving || isClosed) return;
    emit(
      AvatarPickerState(
        loading: true,
        options: state.options,
        selected: state.selected,
      ),
    );
    try {
      final options = await repository.options();
      if (!isClosed) {
        emit(AvatarPickerState(options: options, selected: state.selected));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          AvatarPickerState(
            options: state.options,
            selected: state.selected,
            error: error.toString(),
          ),
        );
      }
    }
  }

  void select(String? id) {
    if (isClosed || state.saving || state.loading) return;
    emit(AvatarPickerState(options: state.options, selected: id));
  }

  Future<void> save() async {
    if (isClosed || state.loading || state.saving) return;
    emit(
      AvatarPickerState(
        saving: true,
        options: state.options,
        selected: state.selected,
      ),
    );
    try {
      final result = await repository.save(state.selected);
      if (!isClosed) {
        emit(
          AvatarPickerState(
            options: state.options,
            selected: result.avatarId,
            saved: result,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          AvatarPickerState(
            options: state.options,
            selected: state.selected,
            error: error.toString(),
          ),
        );
      }
    }
  }
}
