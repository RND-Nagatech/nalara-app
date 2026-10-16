import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/presentation/bloc/progress_form_cubit.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'progress_form_fixtures.dart';

void main() {
  test(
    'domain loader reads actual student/period and all eligible session pages',
    () async {
      final fixture = ProgressFixtures();
      final data = await fixture.load('t1');
      expect(fixture.learning.reads, ['t1']);
      expect(fixture.students.requests, ['get:s1']);
      expect(fixture.learning.planReads, ['p1']);
      expect(data.student.name, 'Alya');
      expect(data.plan.subjectName, 'Matematika');
      expect(fixture.schedules.calls.map((call) => call.page), [1, 2, 3]);
      expect(fixture.schedules.studentIds, everyElement('s1'));
      expect(data.lessons.map((lesson) => lesson.id), ['l1', 'l2']);
      expect(() => data.lessons.clear(), throwsUnsupportedError);
      expect(fixture.learning.writes, isEmpty);
    },
  );
  test(
    'backend errors are not replaced with mock profile/period/session data',
    () async {
      final fixture = ProgressFixtures();
      fixture.students.error = const AppFailure('Siswa tidak dapat diakses');
      await expectLater(
        fixture.load('t1'),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.message,
            'message',
            'Siswa tidak dapat diakses',
          ),
        ),
      );
      expect(fixture.learning.writes, isEmpty);
    },
  );
  test(
    'refresh failure retains the previous draft data, retry updates the server version',
    () async {
      final fixture = ProgressFixtures();
      final cubit = ProgressFormCubit(fixture.load, 't1');
      addTearDown(cubit.close);
      await cubit.load();
      final previous = cubit.state.data;
      fixture.learning.error = const AppFailure(
        'Target berubah. Muat ulang sebelum menyimpan.',
      );
      await cubit.load();
      expect(cubit.state.data, same(previous));
      expect(
        cubit.state.error,
        'Target berubah. Muat ulang sebelum menyimpan.',
      );
      fixture.learning.error = null;
      fixture.learning.current = progressTarget(progress: 60, version: 6);
      await cubit.load();
      expect(cubit.state.data!.target.version, 6);
      expect(cubit.state.data!.target.progress, 60);
      expect(cubit.state.error, isNull);
    },
  );
  test(
    'a newer load wins and pending responses after close are ignored',
    () async {
      final fixture = ProgressFixtures();
      final cubit = ProgressFormCubit(fixture.load, 't1');
      final old = Completer<LearningTarget>();
      fixture.learning.read = () => old.future;
      final first = cubit.load();
      fixture.learning.read = null;
      await cubit.load();
      final newest = cubit.state.data;
      old.completeError(const AppFailure('Old failure'));
      await first;
      expect(cubit.state.data, same(newest));
      expect(cubit.state.error, isNull);
      final disposed = Completer<LearningTarget>();
      fixture.learning.read = () => disposed.future;
      final closing = cubit.load();
      await cubit.close();
      disposed.complete(progressTarget());
      await closing;
      expect(cubit.isClosed, isTrue);
    },
  );
}
