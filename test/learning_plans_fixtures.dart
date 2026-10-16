import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/repositories/learning_repository.dart';
import 'package:nalara/shared/domain/page.dart';

typedef PlansRequest = ({int page, String? studentId});

LearningPlan planFixture(
  String id, {
  String studentId = 's1',
  int? progress = 30,
}) => LearningPlan(
  id: id,
  studentId: studentId,
  subjectId: 'math',
  title: 'Rencana $id',
  studentName: 'Alya',
  subjectName: 'Matematika',
  startAt: DateTime.utc(2026, 10, 12),
  endAt: DateTime.utc(2026, 10, 18),
  progress: progress,
  targetCount: progress == null ? 0 : 2,
);

class LearningRepositoryFake implements LearningRepository {
  final calls = <PlansRequest>[];
  List<LearningPlan> records = [];
  int limit = 30;
  Object? error;
  Future<PageResult<LearningPlan>> Function(PlansRequest request)? respond;
  @override
  Future<PageResult<LearningPlan>> plans({
    int page = 1,
    String? studentId,
  }) async {
    final request = (page: page, studentId: studentId);
    calls.add(request);
    if (respond != null) return await respond!(request);
    if (error != null) throw error!;
    final matches = records
        .where((plan) => studentId == null || plan.studentId == studentId)
        .toList();
    return PageResult(
      items: matches.skip((page - 1) * limit).take(limit).toList(),
      total: matches.length,
      page: page,
      limit: limit,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
