import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/repositories/learning_repository.dart';
import 'package:nalara/features/lesson_reports/domain/entities/lesson_report.dart';
import 'package:nalara/features/lesson_reports/domain/repositories/reports_repository.dart';
import 'package:nalara/features/lesson_reports/domain/usecases/load_report_form.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/repositories/schedules_repository.dart';
import 'package:nalara/shared/domain/page.dart';

class _Schedules implements SchedulesRepository {
  Lesson lesson = Lesson(
    id: 'session-a',
    scheduleId: 'schedule',
    studentId: 'a',
    subjectId: 'math',
    startAt: DateTime.utc(2030),
    endAt: DateTime.utc(2030, 1, 1, 1),
    status: 'scheduled',
    attendance: 'pending',
    studentName: '3 siswa',
    participants: const [
      SessionParticipant(
        sessionId: 'session-a',
        studentId: 'a',
        studentName: 'Andi',
        attendance: 'pending',
        status: 'scheduled',
      ),
      SessionParticipant(
        sessionId: 'session-b',
        studentId: 'b',
        studentName: 'Budi',
        attendance: 'pending',
        status: 'scheduled',
      ),
      SessionParticipant(
        sessionId: 'session-c',
        studentId: 'c',
        studentName: 'Cici',
        attendance: 'pending',
        status: 'cancelled',
      ),
    ],
  );
  @override
  Future<Lesson> session(String id) async => lesson;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Learning implements LearningRepository {
  final calls = <(String?, int)>[];
  final details = <String>[];
  LearningPlan makePlan(String student, String subject) => LearningPlan(
    id: '$student-$subject',
    studentId: student,
    subjectId: subject,
    title: 'Rencana',
    startAt: DateTime.utc(2030),
    endAt: DateTime.utc(2030, 1, 7),
    progress: 0,
    targetCount: 1,
    targets: [
      LearningTarget(
        id: 'target-$student',
        planId: '$student-$subject',
        studentId: student,
        subjectId: subject,
        title: 'Target $student',
        description: '',
        successCriteria: '',
        status: 'active',
        priority: 'normal',
        progress: 0,
        version: 1,
      ),
    ],
  );
  @override
  Future<PageResult<LearningPlan>> plans({
    int page = 1,
    String? studentId,
  }) async {
    calls.add((studentId, page));
    return PageResult(
      items: [makePlan(studentId!, page == 1 ? 'other' : 'math')],
      total: 2,
      page: page,
      limit: 1,
    );
  }

  @override
  Future<LearningPlan> plan(String id) async {
    details.add(id);
    return makePlan(id.split('-').first, 'math');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reports implements ReportsRepository {
  @override
  Future<LessonReport> get(String id) async => LessonReport(
    id: id,
    sessionId: 'session-b',
    studentId: 'b',
    topic: 'Topik',
    summary: 'Ringkasan',
    observations: '',
    difficulties: '',
    homework: '',
    recommendation: '',
    visibility: 'teacher',
    status: 'draft',
    targetIds: const ['target-b'],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Learning learning;
  late _Schedules schedules;
  late LoadReportForm load;
  setUp(() {
    learning = _Learning();
    schedules = _Schedules();
    load = LoadReportForm(_Reports(), schedules, learning);
  });

  test(
    'single child in a group resolves the selected occurrence, not the representative',
    () async {
      final data = await load(sessionId: 'session-b');
      expect(data.recipients.single.studentId, 'b');
      expect(data.recipients.single.studentName, 'Budi');
      expect(data.recipients.single.targets.single.id, 'target-b');
      expect(learning.calls, [('b', 1), ('b', 2)]);
    },
  );

  test(
    'batch loads all plan pages and keeps targets isolated by selected recipient',
    () async {
      final data = await load(
        sessionId: 'session-a',
        sessionIds: ['session-a', 'session-b'],
      );
      expect(data.recipients.map((r) => r.studentId), ['a', 'b']);
      expect(data.recipients.map((r) => r.targets.single.id), [
        'target-a',
        'target-b',
      ]);
      expect(learning.details, ['a-math', 'b-math']);
      expect(learning.calls.any((call) => call.$1 == 'c'), false);
      expect(() => data.recipients.clear(), throwsUnsupportedError);
    },
  );

  test(
    'foreign, duplicate, oversized and cancelled selections fail without a fabricated recipient',
    () async {
      for (final ids in [
        ['foreign'],
        ['session-a', 'session-a'],
        ['session-c'],
        List.generate(101, (index) => 'session-$index'),
      ]) {
        await expectLater(
          load(sessionId: 'session-a', sessionIds: ids),
          throwsStateError,
        );
      }
    },
  );

  test(
    'editing an existing draft ignores group query selection and keeps its own target',
    () async {
      final data = await load(reportId: 'report-b', sessionIds: ['session-a']);
      expect(data.recipients.single.sessionId, 'session-b');
      expect(data.recipients.single.targets.single.id, 'target-b');
      expect(data.report!.targetIds, ['target-b']);
    },
  );
}
