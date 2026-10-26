import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/teaching_guide.dart';

enum TourStage { menu, add, form, editing, save, success }

class TeachingTourState {
  final TeachingGuideStep? step;
  final TourStage stage;
  const TeachingTourState({this.step, this.stage = TourStage.menu});
  bool get active => step != null;
  int get number => switch (stage) {
    TourStage.menu => 1,
    TourStage.add => 2,
    TourStage.form || TourStage.editing => 3,
    TourStage.save => 4,
    TourStage.success => 5,
  };
}

class TeachingTourCubit extends Cubit<TeachingTourState> {
  TeachingTourCubit() : super(const TeachingTourState());
  void start(TeachingGuideStep step) => emit(TeachingTourState(step: step));
  void move(TourStage stage) {
    if (state.active && !isClosed) {
      emit(TeachingTourState(step: state.step, stage: stage));
    }
  }

  void pause() {
    if (!isClosed) emit(const TeachingTourState());
  }
}
