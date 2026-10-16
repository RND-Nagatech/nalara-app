import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/learning_goals/presentation/bloc/plan_form_cubit.dart';
import 'package:nalara/features/schedules/domain/usecases/load_teaching_options.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'plan_form_fixtures.dart';
import 'students_fixtures.dart';

void main() {
  late StudentsRepositoryFake students;
  late PlanSubjectsFake subjects;
  late PlanOptionsFake options;
  late PlanRepositoryFake repository;
  late PlanFormCubit cubit;
  setUp(() {
    students = StudentsRepositoryFake()
      ..records = [
        studentFixture('s1', 'Alya'),
        studentFixture('s2', 'Bima'),
        studentFixture('archived', 'Arsip', status: 'archived'),
      ]
      ..limit = 1;
    subjects = PlanSubjectsFake();
    options = PlanOptionsFake(students, subjects);
    repository = PlanRepositoryFake();
    cubit = PlanFormCubit(options, repository);
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test(
    'loads every active-student/subject page and snapshots choices without source reads',
    () async {
      await cubit.load();
      expect(students.calls.map((call) => call.status), everyElement('active'));
      expect(students.calls.map((call) => call.page), [1, 2]);
      expect(subjects.pages, [1, 2]);
      expect(cubit.state.data!.options.students.map((s) => s.id), ['s1', 's2']);
      expect(
        () => cubit.state.data!.options.subjects.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => cubit.state.data!.options.students.clear(),
        throwsUnsupportedError,
      );
      expect(repository.targetReads, isEmpty);
      expect(repository.planReads, isEmpty);
      expect(cubit.state.loading, isFalse);
      expect(repository.drafts, isEmpty);
    },
  );

  test(
    'continuation reads exact source/plan and does not mutate old progress',
    () async {
      await cubit.close();
      cubit = PlanFormCubit(options, repository, sourceTargetId: 't1');
      await cubit.load();
      expect(repository.targetReads, ['t1']);
      expect(repository.planReads, ['p1']);
      expect(cubit.state.data!.source!.progress, 60);
      expect(cubit.state.data!.sourcePlan!.id, 'p1');
      expect(repository.drafts, isEmpty);
    },
  );

  test(
    'refresh/error/retry retains last choices and forwards backend message',
    () async {
      await cubit.load();
      final loaded = cubit.state.data;
      final pending = Completer<TeachingOptions>();
      options.respond = () => pending.future;
      final refreshing = cubit.load();
      expect(cubit.state.data, same(loaded));
      expect(cubit.state.loading, isTrue);
      pending.completeError(
        const AppFailure('Bidang belajar gagal dimuat. Coba kembali.'),
      );
      await refreshing;
      expect(cubit.state.data, same(loaded));
      expect(cubit.state.error, 'Bidang belajar gagal dimuat. Coba kembali.');
      options.respond = null;
      await cubit.load();
      expect(cubit.state.error, isNull);
      expect(cubit.state.data!.options.subjects.length, 2);
    },
  );

  test(
    'stale result/error and disposed requests never replace newer data',
    () async {
      final old = Completer<TeachingOptions>();
      options.respond = () => old.future;
      final first = cubit.load();
      options.respond = null;
      await cubit.load();
      final newest = cubit.state.data;
      old.completeError(const AppFailure('Stale failure'));
      await first;
      expect(cubit.state.data, same(newest));
      expect(cubit.state.error, isNull);
      final closing = Completer<TeachingOptions>();
      options.respond = () => closing.future;
      final last = cubit.load();
      await cubit.close();
      closing.complete(const TeachingOptions([], []));
      await last;
      expect(cubit.isClosed, isTrue);
    },
  );
}
