import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/teaching_guide.dart';

class TeachingGuideState {
  final TeachingGuide? value;
  final bool loading, saving;
  final String? error;
  const TeachingGuideState({
    this.value,
    this.loading = false,
    this.saving = false,
    this.error,
  });

  bool get busy => loading || saving;
}

class TeachingGuideCubit extends Cubit<TeachingGuideState> {
  final TeachingGuideRepository repository;
  int _generation = 0;
  bool _reloadAfterSave = false;
  TeachingGuideCubit(this.repository) : super(const TeachingGuideState());

  void reset() {
    _generation++;
    _reloadAfterSave = false;
    if (!isClosed) emit(const TeachingGuideState());
  }

  Future<void> load() async {
    if (isClosed) return;
    if (state.saving) {
      _reloadAfterSave = true;
      return;
    }
    final generation = ++_generation;
    emit(TeachingGuideState(value: state.value, loading: true));
    try {
      final value = await repository.get();
      if (!isClosed && generation == _generation) {
        emit(TeachingGuideState(value: value));
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(TeachingGuideState(value: state.value, error: error.toString()));
      }
    }
  }

  Future<void> acknowledgeTutorial() async {
    final value = state.value;
    if (isClosed || state.busy || value == null) return;
    final generation = ++_generation;
    emit(TeachingGuideState(value: value, saving: true));
    try {
      final saved = await repository.acknowledgeTutorial();
      if (!isClosed && generation == _generation) {
        emit(TeachingGuideState(value: value.withTutorialSeen(saved)));
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(TeachingGuideState(value: value, error: error.toString()));
      }
    } finally {
      if (!isClosed && _reloadAfterSave) {
        _reloadAfterSave = false;
        await load();
      }
    }
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
