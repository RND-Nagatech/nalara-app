import '../../../../shared/domain/page.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/repositories/learning_repository.dart';
import '../datasources/learning_remote_source.dart';
import '../models/learning_model.dart';

class LearningRepositoryImpl implements LearningRepository {
  final LearningRemoteSource remote;
  LearningRepositoryImpl(this.remote);
  Map<String, dynamic> fields(TargetDraft draft) => {
    'title': draft.title.trim(),
    'description': draft.description.trim(),
    'successCriteria': draft.successCriteria.trim(),
    'priority': draft.priority,
  };
  @override
  Future<PageResult<LearningPlan>> plans({
    int page = 1,
    String? studentId,
  }) async {
    final json = await remote.plans(page, studentId);
    return PageResult(
      items: (json['items'] as List)
          .map((e) => PlanModel(Map<String, dynamic>.from(e)).toEntity())
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
    );
  }

  @override
  Future<LearningPlan> plan(String id) async =>
      PlanModel(await remote.plan(id)).toEntity();
  @override
  Future<LearningPlan> createPlan(PlanDraft d) async => PlanModel(
    await remote.createPlan({
      'title': d.title.trim(),
      'studentId': d.studentId,
      'subjectId': d.subjectId,
      'startAt': d.startAt.toUtc().toIso8601String(),
      'endAt': d.endAt.toUtc().toIso8601String(),
      'targets': d.targets.map(fields).toList(),
    }),
  ).toEntity();
  @override
  Future<LearningTarget> target(String id) async =>
      TargetModel(await remote.target(id)).toEntity();
  @override
  Future<LearningTarget> addTarget(String planId, TargetDraft draft) async =>
      TargetModel(await remote.addTarget(planId, fields(draft))).toEntity();
  @override
  Future<void> editTarget(String id, TargetDraft draft) =>
      remote.editTarget(id, fields(draft));
  @override
  Future<void> archiveTarget(String id) =>
      remote.editTarget(id, {'status': 'archived'});
  @override
  Future<LearningTarget> updateProgress(String id, ProgressUpdate d) async =>
      TargetModel(
        await remote.progress(id, {
          'progress': d.progress,
          'version': d.version,
          'note': d.note.trim(),
          'visibility': d.visibility,
          if (d.sessionId != null) 'sessionId': d.sessionId,
        }),
      ).toEntity();
}
