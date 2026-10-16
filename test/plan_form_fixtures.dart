import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/schedules/domain/usecases/load_teaching_options.dart';
import 'package:nalara/features/subjects/domain/entities/subject.dart';
import 'package:nalara/features/subjects/domain/repositories/subjects_repository.dart';
import 'package:nalara/shared/domain/page.dart';
import 'learning_plans_fixtures.dart';
import 'students_fixtures.dart';

class PlanSubjectsFake implements SubjectsRepository {
  final pages = <int>[];
  List<Subject> records = [
    const Subject(id: 'math', name: 'Matematika'),
    const Subject(id: 'music', name: 'Piano'),
  ];
  @override
  Future<PageResult<Subject>> list({int page = 1}) async {
    pages.add(page);
    return PageResult(
      items: records.skip(page - 1).take(1).toList(),
      total: records.length,
      page: page,
      limit: 1,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PlanOptionsFake extends LoadTeachingOptions {
  final StudentsRepositoryFake studentsFake;
  final PlanSubjectsFake subjectsFake;
  int calls = 0;
  Object? error;
  Future<TeachingOptions> Function()? respond;
  PlanOptionsFake(this.studentsFake, this.subjectsFake)
    : super(studentsFake, subjectsFake);
  @override
  Future<TeachingOptions> call() async {
    calls++;
    if (respond != null) return await respond!();
    if (error != null) throw error!;
    return super.call();
  }
}

class PlanRepositoryFake extends LearningRepositoryFake {
  final drafts = <PlanDraft>[],
      targetReads = <String>[],
      planReads = <String>[];
  Future<LearningPlan> Function(PlanDraft)? save;
  Future<LearningTarget> Function(String)? readTarget;
  final source = const LearningTarget(
    id: 't1',
    planId: 'p1',
    studentId: 's2',
    subjectId: 'music',
    title: 'Latihan tangga nada',
    description: 'Latihan setiap hari',
    successCriteria: 'Mampu memainkan satu oktaf',
    status: 'active',
    priority: 'high',
    progress: 60,
    version: 3,
  );
  LearningPlan previous = LearningPlan(
    id: 'p1',
    studentId: 's2',
    subjectId: 'music',
    title: 'Periode asal',
    startAt: DateTime.utc(2026, 10, 1, 17),
    endAt: DateTime.utc(2026, 10, 14, 16, 59, 59),
    progress: 60,
    targetCount: 1,
  );
  @override
  Future<LearningTarget> target(String id) async {
    targetReads.add(id);
    return readTarget == null ? source : await readTarget!(id);
  }

  @override
  Future<LearningPlan> plan(String id) async {
    planReads.add(id);
    return previous;
  }

  @override
  Future<LearningPlan> createPlan(PlanDraft draft) async {
    drafts.add(draft);
    return save == null ? planFixture('saved') : await save!(draft);
  }
}
