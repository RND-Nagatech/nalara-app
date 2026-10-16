import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/presentation/bloc/learning_plans_cubit.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'learning_plans_fixtures.dart';

void main() {
  late LearningRepositoryFake repository;
  late LearningPlansCubit cubit;
  setUp(() {
    repository = LearningRepositoryFake();
    cubit = LearningPlansCubit(repository, studentId: 's1');
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test(
    'uses scoped domain repository and preserves server pagination/progress',
    () async {
      repository.records = [
        planFixture('a', progress: null),
        planFixture('b', studentId: 'other'),
        planFixture('c', progress: 0),
      ];
      repository.limit = 1;
      await cubit.refresh();
      expect(repository.calls.single, (page: 1, studentId: 's1'));
      expect(cubit.state.result!.total, 2);
      expect(cubit.state.result!.limit, 1);
      expect(cubit.state.result!.items.single.progress, isNull);
      expect(cubit.state.result!.hasNext, isTrue);
      expect(() => cubit.state.result!.items.clear(), throwsUnsupportedError);
      await cubit.goToPage(2);
      expect(cubit.state.result!.page, 2);
      expect(cubit.state.result!.items.single.progress, 0);
      expect(cubit.state.result!.hasNext, isFalse);
      await cubit.refresh();
      expect(repository.calls.last, (page: 1, studentId: 's1'));
    },
  );

  test(
    'failed pagination retains actual page and retries requested page unchanged',
    () async {
      repository.records = [planFixture('a'), planFixture('b')];
      repository.limit = 1;
      await cubit.refresh();
      const message =
          'Rencana belajar belum dapat dimuat. Silakan coba kembali.';
      repository.error = const AppFailure(message);
      await cubit.goToPage(2);
      expect(cubit.state.error, message);
      expect(cubit.state.result!.page, 1);
      expect(cubit.state.result!.items.single.id, 'a');
      expect(cubit.state.isEmpty, isFalse);
      repository.error = null;
      await cubit.retry();
      expect(repository.calls.last, (page: 2, studentId: 's1'));
      expect(cubit.state.result!.items.single.id, 'b');
    },
  );

  test(
    'only a successful zero-total response is the illustrated empty state',
    () async {
      repository.error = const AppFailure('Jaringan tidak tersedia');
      await cubit.refresh();
      expect(cubit.state.isEmpty, isFalse);
      repository.error = null;
      await cubit.refresh();
      expect(cubit.state.isEmpty, isTrue);
      repository.records = [planFixture('a')];
      await cubit.goToPage(2);
      expect(cubit.state.result!.items, isEmpty);
      expect(cubit.state.result!.total, 1);
      expect(cubit.state.isEmpty, isFalse);
    },
  );

  test(
    'refresh supersedes old pages and duplicate pagination is ignored while busy',
    () async {
      repository.records = [planFixture('a'), planFixture('b')];
      repository.limit = 1;
      await cubit.refresh();
      final old = Completer<PageResult<LearningPlan>>();
      repository.respond = (_) => old.future;
      final next = cubit.goToPage(2);
      await cubit.goToPage(3);
      expect(repository.calls.length, 2);
      expect(cubit.state.result!.page, 1);
      repository.respond = null;
      repository.records = [planFixture('new', progress: 80)];
      await cubit.refresh();
      old.complete(
        PageResult(items: [planFixture('stale')], total: 2, page: 2, limit: 1),
      );
      await next;
      expect(cubit.state.result!.page, 1);
      expect(cubit.state.result!.items.single.id, 'new');
      expect(cubit.state.result!.items.single.progress, 80);
    },
  );

  test(
    'late error cannot replace a refreshed result and closing ignores pending data',
    () async {
      final old = Completer<PageResult<LearningPlan>>();
      repository.respond = (_) => old.future;
      final pending = cubit.refresh();
      repository.respond = null;
      await cubit.refresh();
      old.completeError(const AppFailure('Old failure'));
      await pending;
      expect(cubit.state.error, isNull);
      expect(cubit.state.isEmpty, isTrue);
      final closing = Completer<PageResult<LearningPlan>>();
      repository.respond = (_) => closing.future;
      final last = cubit.refresh();
      await cubit.close();
      closing.complete(
        const PageResult(items: [], total: 0, page: 1, limit: 30),
      );
      await last;
      expect(cubit.isClosed, isTrue);
    },
  );
}
