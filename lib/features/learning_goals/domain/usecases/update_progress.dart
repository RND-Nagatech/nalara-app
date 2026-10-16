import '../../../../shared/errors/app_failure.dart';
import '../entities/learning_goal.dart';
import '../repositories/learning_repository.dart';

class UpdateProgress {
  final LearningRepository repository;
  UpdateProgress(this.repository);
  Future<LearningTarget> call(String id, ProgressUpdate update) {
    if (update.progress < 0 || update.progress > 100) {
      throw const AppFailure('Progress harus 0–100');
    }
    if (!['teacher', 'shared'].contains(update.visibility)) {
      throw const AppFailure('Visibilitas tidak valid');
    }
    return repository.updateProgress(id, update);
  }
}

class PlanProgressLabel {
  // Aggregate is canonical on the server; null is a distinct domain state.
  String call(LearningPlan plan) =>
      plan.progress == null ? 'Belum ada target' : '${plan.progress}%';
}
