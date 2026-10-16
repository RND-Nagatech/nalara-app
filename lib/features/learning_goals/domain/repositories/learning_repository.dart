import '../../../../shared/domain/page.dart';
import '../entities/learning_goal.dart';

abstract class LearningRepository {
  Future<PageResult<LearningPlan>> plans({int page = 1, String? studentId});
  Future<LearningPlan> plan(String id);
  Future<LearningPlan> createPlan(PlanDraft draft);
  Future<LearningTarget> target(String id);
  Future<LearningTarget> addTarget(String planId, TargetDraft draft);
  Future<void> editTarget(String id, TargetDraft draft);
  Future<void> archiveTarget(String id);
  Future<LearningTarget> updateProgress(String id, ProgressUpdate update);
}
