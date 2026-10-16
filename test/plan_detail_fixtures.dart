import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/usecases/load_plan_overview.dart';
import 'learning_plans_fixtures.dart';
import 'student_detail_fixtures.dart';

LearningTarget planDetailTarget(
  String id, {
  int progress = 20,
  String status = 'active',
}) => LearningTarget(
  id: id,
  planId: 'p1',
  studentId: 's1',
  subjectId: 'math',
  title: 'Memahami pecahan $id',
  description: '',
  successCriteria: 'Mampu mengerjakan semua soal',
  status: status,
  priority: 'normal',
  progress: progress,
  version: 3,
);

LearningPlan detailPlan({
  String id = 'p1',
  String studentId = 's1',
  String title = 'Rencana belajar Oktober',
  String subject = 'Matematika',
  int? progress = 37,
  List<LearningTarget>? targets,
}) => LearningPlan(
  id: id,
  studentId: studentId,
  subjectId: 'math',
  title: title,
  studentName: 'Nama lama dari enrichment',
  subjectName: subject,
  startAt: DateTime.utc(2026, 10, 14, 17),
  endAt: DateTime.utc(2026, 10, 19, 16, 59, 59),
  progress: progress,
  targetCount: progress == null ? 0 : 1,
  targets: targets ?? [planDetailTarget('t1')],
);

class PlanDetailLearningFake extends LearningRepositoryFake {
  LearningPlan current = detailPlan();
  final requests = <String>[];
  Future<LearningPlan> Function(String)? respondPlan;
  @override
  Future<LearningPlan> plan(String id) async {
    requests.add(id);
    if (respondPlan != null) return await respondPlan!(id);
    if (error != null) throw error!;
    return current;
  }
}

class PlanDetailFixtures {
  final learning = PlanDetailLearningFake();
  final students = DetailStudentsFake();
  late final load = LoadPlanOverview(learning, students);
}
