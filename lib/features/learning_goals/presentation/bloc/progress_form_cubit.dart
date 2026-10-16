import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/progress_form_data.dart';
import '../../domain/usecases/load_progress_form.dart';

class ProgressFormState {
  final ProgressFormData? data;
  final bool loading;
  final String? error;
  const ProgressFormState({this.data, this.loading = false, this.error});
}

class ProgressFormCubit extends Cubit<ProgressFormState> {
  final LoadProgressForm loadForm;
  final String id;
  int _generation = 0;
  ProgressFormCubit(this.loadForm, this.id) : super(const ProgressFormState());
  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_generation;
    emit(ProgressFormState(data: state.data, loading: true));
    try {
      final data = await loadForm(id);
      if (isClosed || generation != _generation) return;
      emit(ProgressFormState(data: data));
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(ProgressFormState(data: state.data, error: error.toString()));
    }
  }
}
