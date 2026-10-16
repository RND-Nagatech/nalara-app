import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../schedules/domain/usecases/load_teaching_options.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/repositories/learning_repository.dart';

class PlanFormData {
  final TeachingOptions options;
  final LearningTarget? source;
  final LearningPlan? sourcePlan;
  PlanFormData({required TeachingOptions options, this.source, this.sourcePlan})
    : options = TeachingOptions(
        List.unmodifiable(options.students),
        List.unmodifiable(options.subjects),
      );
}

class PlanFormState {
  final PlanFormData? data;
  final bool loading;
  final String? error;
  const PlanFormState({this.data, this.loading = false, this.error});
}

/// Keeps loaded choices/drafts visible during catalog refresh and failed retries.
class PlanFormCubit extends Cubit<PlanFormState> {
  final LoadTeachingOptions loadOptions;
  final LearningRepository repository;
  final String? sourceTargetId;
  int _generation = 0;
  PlanFormCubit(this.loadOptions, this.repository, {this.sourceTargetId})
    : super(const PlanFormState());

  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_generation;
    emit(PlanFormState(data: state.data, loading: true));
    try {
      final options = await loadOptions();
      if (isClosed || generation != _generation) return;
      final source = sourceTargetId == null
          ? null
          : await repository.target(sourceTargetId!);
      if (isClosed || generation != _generation) return;
      final sourcePlan = source == null
          ? null
          : await repository.plan(source.planId);
      if (isClosed || generation != _generation) return;
      emit(
        PlanFormState(
          data: PlanFormData(
            options: options,
            source: source,
            sourcePlan: sourcePlan,
          ),
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(PlanFormState(data: state.data, error: error.toString()));
    }
  }
}
