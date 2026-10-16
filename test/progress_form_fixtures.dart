import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/usecases/load_progress_form.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/shared/domain/page.dart';
import 'learning_plans_fixtures.dart';
import 'schedule_fixtures.dart';
import 'student_detail_fixtures.dart';

LearningTarget progressTarget({int progress = 20, int version = 5}) =>
    LearningTarget(
      id: 't1',
      planId: 'p1',
      studentId: 's1',
      subjectId: 'math',
      title: 'Operasi pecahan',
      description: '',
      successCriteria: '',
      status: 'active',
      priority: 'normal',
      progress: progress,
      version: version,
    );
Lesson progressLesson(
  String id,
  int day, {
  String studentId = 's1',
  String subjectId = 'math',
  String status = 'scheduled',
}) => Lesson(
  id: id,
  scheduleId: 'series',
  studentId: studentId,
  subjectId: subjectId,
  startAt: DateTime.utc(2026, 10, day, 3),
  endAt: DateTime.utc(2026, 10, day, 4),
  status: status,
  attendance: 'pending',
  subjectName: 'Matematika',
);

class ProgressLearningFake extends LearningRepositoryFake {
  final reads = <String>[], planReads = <String>[];
  final writes = <({String id, ProgressUpdate update})>[];
  LearningTarget current = progressTarget();
  Future<LearningTarget> Function()? read;
  Future<LearningTarget> Function(ProgressUpdate)? update;
  @override
  Future<LearningTarget> target(String id) async {
    reads.add(id);
    if (error != null) throw error!;
    return read == null ? current : await read!();
  }

  @override
  Future<LearningPlan> plan(String id) async {
    planReads.add(id);
    return planFixture('p1');
  }

  @override
  Future<LearningTarget> updateProgress(String id, ProgressUpdate value) async {
    writes.add((id: id, update: value));
    if (update != null) return await update!(value);
    current = progressTarget(
      progress: value.progress,
      version: value.version + 1,
    );
    return current;
  }
}

class ProgressSchedulesFake extends ScheduleRepositoryFake {
  final studentIds = <String?>[];
  @override
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
    String? studentId,
    String? scheduleId,
  }) {
    studentIds.add(studentId);
    return super.sessions(
      page: page,
      from: from,
      to: to,
      studentId: studentId,
      scheduleId: scheduleId,
    );
  }
}

class ProgressFixtures {
  final learning = ProgressLearningFake();
  final students = DetailStudentsFake();
  final schedules = ProgressSchedulesFake()
    ..limit = 2
    ..records = [
      progressLesson('l1', 16),
      progressLesson('cancelled', 17, status: 'cancelled'),
      progressLesson('l2', 18, status: 'completed'),
      progressLesson('wrong-subject', 19, subjectId: 'music'),
      progressLesson('wrong-student', 20, studentId: 'other'),
    ];
  late final load = LoadProgressForm(learning, students, schedules);
}
