import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/domain/entities/student_filter.dart';
import 'package:nalara/features/students/domain/usecases/load_students.dart';
import 'package:nalara/features/students/presentation/bloc/students_cubit.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'students_fixtures.dart';

void main() {
  late StudentsRepositoryFake repository;
  late StudentsCubit cubit;
  setUp(() {
    repository = StudentsRepositoryFake()
      ..records = [
        studentFixture('a', 'Alya'),
        studentFixture('b', 'Bima'),
        studentFixture('c', 'Citra', status: 'archived'),
      ];
    cubit = StudentsCubit(LoadStudents(repository));
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });
  Future<void> tick() => Future<void>.delayed(Duration.zero);
  PageResult<Student> response(String name, {int page = 1}) => PageResult(
    items: [studentFixture(name, name)],
    total: 40,
    page: page,
    limit: 30,
  );

  test(
    'domain filter forwards active/archived/all to the existing backend repository',
    () async {
      for (final filter in StudentFilter.values) {
        await LoadStudents(repository)(
          filter: filter,
          search: '  Al  ',
          page: 2,
        );
      }
      expect(repository.calls, [
        (page: 2, search: 'Al', status: 'active'),
        (page: 2, search: 'Al', status: 'archived'),
        (page: 2, search: 'Al', status: null),
      ]);
    },
  );
  test(
    'use case preserves server totals/page/limit and exposes an immutable snapshot',
    () async {
      final source = [studentFixture('a', 'Alya')];
      repository.respond = (_) async =>
          PageResult(items: source, total: 47, page: 2, limit: 30);
      final data = await LoadStudents(repository)(page: 2);
      expect(
        (data.total, data.page, data.limit, data.hasNext),
        (47, 2, 30, false),
      );
      expect(() => data.items.clear(), throwsUnsupportedError);
      source.clear();
      expect(data.items.single.name, 'Alya');
    },
  );
  test(
    'tabs load lazily and cache separate server pages without inventing rows',
    () async {
      repository.limit = 1;
      await cubit.select(StudentFilter.active);
      expect(repository.calls, hasLength(1));
      expect(cubit.state.current.data!.items.single.name, 'Alya');
      await cubit.page(2);
      expect(cubit.state.current.data!.items.single.name, 'Bima');
      await cubit.select(StudentFilter.archived);
      expect(cubit.state.current.data!.items.single.name, 'Citra');
      await cubit.select(StudentFilter.active);
      expect(repository.calls, hasLength(3));
      expect(cubit.state.current.data!.page, 2);
      await cubit.select(StudentFilter.all);
      expect(cubit.state.current.data!.total, 3);
      expect(repository.calls.last.status, isNull);
    },
  );
  test(
    'load more appends the next server batch to the current filter',
    () async {
      repository.limit = 1;
      await cubit.select(StudentFilter.active);
      await cubit.loadMore();
      expect(cubit.state.current.data!.items.map((student) => student.name), [
        'Alya',
        'Bima',
      ]);
      expect(cubit.state.current.data!.page, 2);
      expect(cubit.state.current.data!.hasNext, isFalse);
      expect(repository.calls.map((call) => call.page), [1, 2]);
    },
  );
  testWidgets(
    'debounced typing requests only the latest query and resets every tab to page one',
    (tester) async {
      repository.limit = 1;
      await cubit.select(StudentFilter.active);
      await cubit.page(2);
      await cubit.select(StudentFilter.archived);
      await cubit.select(StudentFilter.active);
      final before = repository.calls.length;
      cubit.search('A');
      await tester.pump(const Duration(milliseconds: 200));
      cubit.search('Al');
      await tester.pump(const Duration(milliseconds: 349));
      expect(repository.calls, hasLength(before));
      expect(cubit.state.current.data, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(repository.calls, hasLength(before + 1));
      expect(repository.calls.last, (page: 1, search: 'Al', status: 'active'));
      expect(cubit.state.current.data!.items.single.name, 'Alya');
      await cubit.select(StudentFilter.archived);
      expect(repository.calls.last.search, 'Al');
      expect(cubit.state.current.data!.items, isEmpty);
      cubit.search('', immediate: true);
      await tester.pump();
      expect(repository.calls.last, (page: 1, search: '', status: 'archived'));
      expect(cubit.state.current.data!.items.single.name, 'Citra');
    },
  );
  test(
    'switching during a debounce cancels its timer and immediately loads the destination filter',
    () async {
      cubit.search('Ci');
      await cubit.select(StudentFilter.archived);
      expect(repository.calls.single, (
        page: 1,
        search: 'Ci',
        status: 'archived',
      ));
      expect(cubit.state.current.data!.items.single.name, 'Citra');
    },
  );
  test(
    'late old-search responses cannot overwrite the latest request',
    () async {
      final old = Completer<PageResult<Student>>(),
          latest = Completer<PageResult<Student>>();
      repository.respond = (request) =>
          request.search.isEmpty ? old.future : latest.future;
      final initial = cubit.select(StudentFilter.active);
      cubit.search('new', immediate: true);
      latest.complete(response('new'));
      await tick();
      expect(cubit.state.current.data!.items.single.name, 'new');
      old.complete(response('old'));
      await initial;
      expect(cubit.state.current.data!.items.single.name, 'new');
    },
  );
  test(
    'cross-tab completion retains its own data without selecting the wrong tab',
    () async {
      final active = Completer<PageResult<Student>>(),
          archived = Completer<PageResult<Student>>();
      repository.respond = (request) =>
          request.status == 'active' ? active.future : archived.future;
      final first = cubit.select(StudentFilter.active);
      final second = cubit.select(StudentFilter.archived);
      archived.complete(response('archived'));
      await second;
      active.complete(response('active'));
      await first;
      expect(cubit.state.selected, StudentFilter.archived);
      expect(cubit.state.current.data!.items.single.name, 'archived');
      expect(
        cubit.state.forFilter(StudentFilter.active).data!.items.single.name,
        'active',
      );
    },
  );
  test('repeated tab taps do not duplicate an in-flight request', () async {
    final pending = Completer<PageResult<Student>>();
    repository.respond = (_) => pending.future;
    final first = cubit.select(StudentFilter.active);
    await cubit.select(StudentFilter.active);
    expect(repository.calls, hasLength(1));
    pending.complete(response('Alya'));
    await first;
  });
  test(
    'refresh after a mutation resets page and invalidates cached other filters',
    () async {
      await cubit.select(StudentFilter.all);
      await cubit.select(StudentFilter.active);
      repository.records.add(studentFixture('d', 'Dina'));
      await cubit.refresh();
      expect(cubit.state.current.data!.total, 3);
      expect(cubit.state.forFilter(StudentFilter.all).data, isNull);
      await cubit.select(StudentFilter.all);
      expect(cubit.state.current.data!.total, 4);
    },
  );
  test(
    'backend failure is not relabeled as empty and retry uses the failed page',
    () async {
      repository.limit = 1;
      await cubit.select(StudentFilter.active);
      repository.error = const AppFailure(
        'Data siswa belum dapat dimuat. Silakan coba lagi.',
        code: 'UNAVAILABLE',
      );
      await cubit.page(2);
      expect(
        cubit.state.current.error,
        'Data siswa belum dapat dimuat. Silakan coba lagi.',
      );
      expect(cubit.state.current.data!.items.single.name, 'Alya');
      expect(cubit.state.current.requestedPage, 2);
      repository.error = null;
      await cubit.retry(StudentFilter.active);
      expect(cubit.state.current.data!.items.single.name, 'Bima');
      expect(cubit.state.current.error, isNull);
    },
  );
  test('initial backend error has no dummy or empty-success data', () async {
    repository.error = const AppFailure(
      'Tidak terhubung ke server.',
      code: 'NETWORK',
    );
    await cubit.select(StudentFilter.active);
    expect(cubit.state.current.data, isNull);
    expect(cubit.state.current.error, 'Tidak terhubung ke server.');
  });
  test(
    'close cancels pending search and ignores a completing old request',
    () async {
      final pending = Completer<PageResult<Student>>();
      repository.respond = (_) => pending.future;
      final first = cubit.select(StudentFilter.active);
      cubit.search('new');
      await cubit.close();
      pending.complete(response('old'));
      await first;
      expect(repository.calls, hasLength(1));
      expect(cubit.isClosed, isTrue);
    },
  );
}
