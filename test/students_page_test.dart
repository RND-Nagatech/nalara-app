import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/domain/entities/student_filter.dart';
import 'package:nalara/features/students/domain/usecases/load_students.dart';
import 'package:nalara/features/students/presentation/bloc/students_cubit.dart';
import 'package:nalara/features/students/presentation/pages/students_pages.dart';
import 'package:nalara/features/students/presentation/widgets/students_style.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'students_fixtures.dart';

void main() {
  late StudentsRepositoryFake repository;
  late StudentsCubit cubit;
  setUp(() {
    repository = StudentsRepositoryFake();
    getIt.registerFactory<StudentsCubit>(() {
      cubit = StudentsCubit(LoadStudents(repository));
      return cubit;
    });
  });
  tearDown(() async => getIt.reset());
  void viewport(WidgetTester tester, [Size size = const Size(390, 844)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(
    WidgetTester tester, {
    double scale = 1,
    double keyboard = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 24, bottom: 18),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: const StudentsPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder body() =>
      find.byKey(ValueKey('students-body-${cubit.state.selected.name}'));
  Finder inside(Finder finder) => find.descendant(of: body(), matching: finder);
  Future<GoRouter> routed(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/teacher/students',
      routes: [
        GoRoute(
          path: '/teacher/students',
          builder: (_, _) => const StudentsPage(),
        ),
        GoRoute(
          path: '/teacher/students/new',
          builder: (_, _) => const Scaffold(body: Text('Form siswa')),
        ),
        GoRoute(
          path: '/teacher/students/a',
          builder: (_, _) => const Scaffold(body: Text('Detail Alya')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'mockup header, pill search, default active tab and supplied empty asset',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Siswa'), findsOneWidget);
      expect(find.text('Kelola data siswa Anda'), findsOneWidget);
      expect(find.text('Cari siswa'), findsOneWidget);
      expect(tester.getRect(find.text('Siswa')).top, greaterThanOrEqualTo(24));
      expect(
        tester
            .widget<TabBar>(find.byKey(const ValueKey('students-tabs')))
            .controller!
            .index,
        0,
      );
      expect(repository.calls.single, (page: 1, search: '', status: 'active'));
      expect(
        inside(find.text('Belum ada siswa yang sesuai pencarian.')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Image>(
              inside(find.byKey(const ValueKey('students-empty-artwork'))),
            )
            .image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'asset',
          StudentsStyle.emptyArtwork,
        ),
      );
      expect(
        inside(
          find.text(
            'Mulai tambahkan siswa untuk mengelola jadwal, materi, dan perkembangan mereka.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        inside(find.widgetWithText(FilledButton, 'Tambah sekarang')),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'tab taps and horizontal swipes in both directions keep the indicator and server filter aligned',
    (tester) async {
      viewport(tester);
      await render(tester);
      final pages = find.byKey(const ValueKey('students-tab-view'));
      Future<void> selected(int index, StudentFilter filter) async {
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TabBar>(find.byKey(const ValueKey('students-tabs')))
              .controller!
              .index,
          index,
        );
        expect(cubit.state.selected, filter);
      }

      await tester.drag(pages, const Offset(-350, 0));
      await selected(1, StudentFilter.archived);
      expect(repository.calls.last.status, 'archived');
      await tester.drag(pages, const Offset(-350, 0));
      await selected(2, StudentFilter.all);
      expect(repository.calls.last.status, isNull);
      await tester.drag(pages, const Offset(350, 0));
      await selected(1, StudentFilter.archived);
      await tester.drag(pages, const Offset(350, 0));
      await selected(0, StudentFilter.active);
      expect(repository.calls, hasLength(3));
      await tester.tap(find.byKey(const ValueKey('students-tab-all')));
      await selected(2, StudentFilter.all);
      await tester.tap(find.byKey(const ValueKey('students-tab-active')));
      await selected(0, StudentFilter.active);
      expect(repository.calls, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'active/archive/all show their actual backend rows, not local placeholder lists',
    (tester) async {
      viewport(tester);
      repository.records = [
        studentFixture('a', 'Alya'),
        studentFixture('c', 'Citra', status: 'archived'),
      ];
      await render(tester);
      expect(inside(find.text('Alya')), findsOneWidget);
      expect(inside(find.text('Citra')), findsNothing);
      expect(inside(find.text('Kelas 5')), findsOneWidget);
      expect(
        inside(find.byKey(const ValueKey('students-empty-artwork'))),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('students-add')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('students-tab-archived')));
      await tester.pumpAndSettle();
      expect(inside(find.text('Citra')), findsOneWidget);
      expect(inside(find.text('Kelas 5')), findsOneWidget);
      expect(inside(find.text('Diarsipkan')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('students-tab-all')));
      await tester.pumpAndSettle();
      expect(inside(find.text('Alya')), findsOneWidget);
      expect(inside(find.text('Citra')), findsOneWidget);
    },
  );
  testWidgets(
    'search is debounced/shared across tabs, submit runs immediately and clear resets query',
    (tester) async {
      viewport(tester);
      repository.records = [
        studentFixture('a', 'Alya'),
        studentFixture('b', 'Bima'),
        studentFixture('c', 'Alya Arsip', status: 'archived'),
      ];
      await render(tester);
      await tester.enterText(
        find.byKey(const ValueKey('students-search')),
        'Al',
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(repository.calls, hasLength(1));
      await tester.enterText(
        find.byKey(const ValueKey('students-search')),
        'Alya',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(repository.calls, hasLength(2));
      expect(inside(find.text('Bima')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('students-tab-archived')));
      await tester.pumpAndSettle();
      expect(repository.calls.last, (
        page: 1,
        search: 'Alya',
        status: 'archived',
      ));
      expect(inside(find.text('Alya Arsip')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('students-search')),
        'Citra',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(repository.calls.last.search, 'Citra');
      expect(
        inside(find.byKey(const ValueKey('students-empty-artwork'))),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('students-clear-search')));
      await tester.pumpAndSettle();
      expect(repository.calls.last, (page: 1, search: '', status: 'archived'));
      expect(inside(find.text('Alya Arsip')), findsOneWidget);
    },
  );
  testWidgets(
    'load more appends the next batch and header reload resets to page one',
    (tester) async {
      viewport(tester);
      repository.limit = 1;
      repository.records = [
        studentFixture('a', 'Alya'),
        studentFixture('b', 'Bima'),
        studentFixture('c', 'Citra', status: 'archived'),
      ];
      await render(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('students-load-more-active')),
      );
      await tester.tap(find.byKey(const ValueKey('students-load-more-active')));
      await tester.pumpAndSettle();
      expect(repository.calls.last.page, 2);
      expect(inside(find.text('Alya')), findsOneWidget);
      expect(inside(find.text('Bima')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('students-tab-archived')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('students-tab-active')));
      await tester.pumpAndSettle();
      expect(cubit.state.current.data!.page, 2);
      final count = repository.calls.length;
      await tester.ensureVisible(
        find.byKey(const ValueKey('students-refresh')),
      );
      await tester.tap(find.byKey(const ValueKey('students-refresh')));
      await tester.pumpAndSettle();
      expect(repository.calls, hasLength(count + 1));
      expect(repository.calls.last.page, 1);
      expect(inside(find.text('Alya')), findsOneWidget);
    },
  );
  testWidgets(
    'backend errors preserve header/search/tabs and retry without showing a fake empty state',
    (tester) async {
      viewport(tester);
      repository.error = const AppFailure(
        'Data siswa tidak dapat dimuat. Silakan coba lagi.',
        code: 'UNAVAILABLE',
      );
      await render(tester);
      expect(find.text('Kelola data siswa Anda'), findsOneWidget);
      expect(find.byKey(const ValueKey('students-search')), findsOneWidget);
      expect(find.byKey(const ValueKey('students-tabs')), findsOneWidget);
      expect(
        inside(find.text('Data siswa tidak dapat dimuat. Silakan coba lagi.')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('students-empty-artwork')),
        findsNothing,
      );
      repository.error = null;
      await tester.tap(inside(find.text('Coba lagi')));
      await tester.pumpAndSettle();
      expect(repository.calls, hasLength(2));
      expect(
        inside(find.byKey(const ValueKey('students-empty-artwork'))),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'initial loading has no invented students or empty-success illustration',
    (tester) async {
      viewport(tester);
      final pending = Completer<PageResult<Student>>();
      repository.respond = (_) => pending.future;
      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const StudentsPage()),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('students-empty-artwork')),
        findsNothing,
      );
      expect(find.text('Alya'), findsNothing);
      pending.complete(
        const PageResult(items: [], total: 0, page: 1, limit: 30),
      );
      await tester.pumpAndSettle();
      expect(
        inside(find.byKey(const ValueKey('students-empty-artwork'))),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'empty CTA opens the existing add form and reloads all filters after return',
    (tester) async {
      viewport(tester);
      final router = await routed(tester);
      await tester.tap(find.byKey(const ValueKey('students-tab-all')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        inside(find.byKey(const ValueKey('students-add-empty'))),
      );
      await tester.tap(
        inside(find.byKey(const ValueKey('students-add-empty'))),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/teacher/students/new');
      repository.records.add(studentFixture('a', 'Alya'));
      router.pop();
      await tester.pumpAndSettle();
      expect(repository.calls.last.status, isNull);
      expect(inside(find.text('Alya')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('students-tab-active')));
      await tester.pumpAndSettle();
      expect(repository.calls.last.status, 'active');
      expect(inside(find.text('Alya')), findsOneWidget);
    },
  );
  testWidgets(
    'real list card opens detail and reflects an archived student after returning',
    (tester) async {
      viewport(tester);
      repository.records = [studentFixture('a', 'Alya')];
      final router = await routed(tester);
      await tester.tap(inside(find.text('Alya')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/teacher/students/a');
      repository.records = [studentFixture('a', 'Alya', status: 'archived')];
      router.pop();
      await tester.pumpAndSettle();
      expect(
        inside(find.byKey(const ValueKey('students-empty-artwork'))),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('students-tab-archived')));
      await tester.pumpAndSettle();
      expect(inside(find.text('Alya')), findsOneWidget);
    },
  );
  testWidgets(
    '320px, large text and keyboard stay scrollable with safe-area padding',
    (tester) async {
      viewport(tester, const Size(320, 640));
      await render(tester, scale: 2, keyboard: 220);
      expect(tester.getRect(find.text('Siswa')).top, greaterThanOrEqualTo(24));
      final inner = find.descendant(
        of: find.byKey(const PageStorageKey('students-list-active')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        inside(find.byKey(const ValueKey('students-add-empty'))),
        200,
        scrollable: inner.first,
      );
      expect(
        inside(find.byKey(const ValueKey('students-add-empty'))),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'leaving the page cancels the pending debounce/controller lifecycle',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tester.enterText(
        find.byKey(const ValueKey('students-search')),
        'pending',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.isClosed, isTrue);
      expect(repository.calls, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
