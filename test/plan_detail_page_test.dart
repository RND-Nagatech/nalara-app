import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/usecases/load_plan_overview.dart';
import 'package:nalara/features/learning_goals/presentation/pages/learning_pages.dart';
import 'package:nalara/features/learning_goals/presentation/widgets/plan_detail_style.dart';
import 'package:nalara/shared/domain/teaching_catalog_changes.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/widgets/teacher_bottom_navigation.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'plan_detail_fixtures.dart';
import 'student_detail_fixtures.dart';

void main() {
  late PlanDetailFixtures fixture;
  late TeachingCatalogChanges catalog;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    fixture = PlanDetailFixtures();
    catalog = TeachingCatalogChanges();
    getIt.registerSingleton<LoadPlanOverview>(fixture.load);
    getIt.registerSingleton<TeachingCatalogChanges>(catalog);
  });
  tearDown(() async {
    await catalog.close();
    await getIt.reset();
  });
  Finder key(String value) => find.byKey(ValueKey('plan-$value'));
  void viewport(WidgetTester tester, [Size size = const Size(430, 1000)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(
    WidgetTester tester, {
    String id = 'p1',
    double scale = 1,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 30, bottom: 20),
          ),
          child: child!,
        ),
        home: PlanDetailPage(id: id),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    final scrollable = find
        .descendant(
          of: key('detail-scroll-p1'),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(finder, 180, scrollable: scrollable);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<GoRouter> routed(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/teacher/plans/p1',
      routes: [
        GoRoute(
          path: '/teacher/plans/p1',
          builder: (_, _) => const PlanDetailPage(id: 'p1'),
        ),
        for (final route in [
          ...teacherNavigationLocations,
          '/teacher/students/s1',
          '/teacher/targets/t1',
          '/teacher/plans/p1/targets/new',
        ])
          GoRoute(
            path: route,
            builder: (_, _) => Scaffold(body: Text('Tujuan $route')),
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

  test(
    'use case reads scoped plan/student and retains canonical aggregate plus all target rows',
    () async {
      final targets = [
        planDetailTarget('t1', progress: 80),
        planDetailTarget('old', status: 'archived'),
      ];
      fixture.learning.current = detailPlan(progress: 37, targets: targets);
      final data = await fixture.load('p1');
      expect(fixture.learning.requests, ['p1']);
      expect(fixture.students.requests, ['get:s1']);
      expect(
        data.plan.progress,
        37,
      ); // Never recomputed from the visible targets.
      expect(data.targets.length, 2);
      expect(() => data.targets.clear(), throwsUnsupportedError);
      targets.clear();
      expect(data.targets.length, 2);
      fixture.students.error = const AppFailure(
        'Status siswa tidak dapat diakses',
      );
      await expectLater(fixture.load('p1'), throwsA(isA<AppFailure>()));
    },
  );

  testWidgets(
    'mockup structure/safe area and real information use backend values',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        PlanDetailStyle.cream,
      );
      expect(tester.getRect(key('detail-back')).top, greaterThanOrEqualTo(30));
      expect(find.text('Rencana belajar'), findsOneWidget);
      expect(find.text('Rencana belajar Oktober'), findsOneWidget);
      expect(find.text('Alya'), findsOneWidget);
      expect(find.text('Nama lama dari enrichment'), findsNothing);
      expect(find.text('Matematika'), findsOneWidget);
      expect(find.text('15 Okt 2026 – 19 Okt 2026'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      expect(tester.widget<Text>(key('overall-value')).data, '37%');
      final track = find.descendant(
        of: key('overall-track'),
        matching: find.byType(LinearProgressIndicator),
      );
      expect(tester.widget<LinearProgressIndicator>(track).value, .37);
      await tester.ensureVisible(key('target-count'));
      expect(find.text('1 target'), findsOneWidget);
      expect(find.text('Aktif · Prioritas Normal'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(tester.takeException(), isNull);
      await render(tester);
      expect(fixture.learning.requests, ['p1']); // Rebuild is not a reload.
    },
  );

  for (final progress in <int?>[null, 0]) {
    testWidgets(
      'aggregate $progress is not replaced by a fake zero or indeterminate bar',
      (tester) async {
        viewport(tester);
        fixture.learning.current = detailPlan(progress: progress, targets: []);
        await render(tester);
        expect(
          tester.widget<Text>(key('overall-value')).data,
          progress == null ? '—' : '0%',
        );
        expect(
          key('overall-track'),
          progress == null ? findsNothing : findsOneWidget,
        );
        expect(
          find.text('Belum ada target dalam periode ini.'),
          findsOneWidget,
        );
        expect(find.text('0 target'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'archived student status is real, while archived targets remain in the list count',
    (tester) async {
      viewport(tester);
      fixture.students.current = detailStudent(status: 'archived');
      fixture.learning.current = detailPlan(
        progress: null,
        targets: [planDetailTarget('old', status: 'archived')],
      );
      await render(tester);
      expect(find.text('Diarsipkan'), findsOneWidget);
      expect(tester.widget<Text>(key('overall-value')).data, '—');
      expect(find.text('1 target'), findsOneWidget);
      expect(find.text('Diarsipkan · Prioritas Normal'), findsOneWidget);
    },
  );

  testWidgets(
    'loading/error/retry, pull refresh and catalog updates reload without dummy cards',
    (tester) async {
      viewport(tester);
      final pending = Completer<LearningPlan>();
      fixture.learning.respondPlan = (_) => pending.future;
      await render(tester, settle: false);
      expect(key('info-card'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(const AppFailure('Rencana belum dapat dimuat'));
      await tester.pumpAndSettle();
      expect(find.text('Rencana belum dapat dimuat'), findsOneWidget);
      fixture.learning.respondPlan = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(key('info-card'), findsOneWidget);
      await tester.drag(key('detail-scroll-p1'), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(fixture.learning.requests.length, 3);
      catalog.notifyChanged();
      await tester.pumpAndSettle();
      expect(fixture.learning.requests.length, 4);
    },
  );

  testWidgets(
    'student/target/add actions preserve routes and refresh on return',
    (tester) async {
      viewport(tester);
      final router = await routed(tester);
      for (final action in [
        (id: 'open-student', route: '/teacher/students/s1'),
        (id: 'target-t1', route: '/teacher/targets/t1'),
        (id: 'add-target', route: '/teacher/plans/p1/targets/new'),
      ]) {
        final calls = fixture.learning.requests.length;
        await tap(tester, key(action.id));
        expect(find.text('Tujuan ${action.route}'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(fixture.learning.requests.length, calls + 1);
      }
      await tester.tap(key('detail-back'));
      await tester.pumpAndSettle();
      expect(find.text('Tujuan /teacher/targets'), findsOneWidget);
    },
  );

  for (var index = 0; index < teacherNavigationLocations.length; index++) {
    testWidgets('bottom destination $index opens the existing root', (
      tester,
    ) async {
      viewport(tester);
      await routed(tester);
      final navigation = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      navigation.onDestinationSelected!(index);
      await tester.pumpAndSettle();
      expect(
        find.text('Tujuan ${teacherNavigationLocations[index]}'),
        findsOneWidget,
      );
    });
  }

  testWidgets('ID change and disposal ignore pending detail requests', (
    tester,
  ) async {
    viewport(tester);
    final old = Completer<LearningPlan>();
    fixture.learning.respondPlan = (_) => old.future;
    await render(tester, settle: false);
    fixture.learning.respondPlan = null;
    fixture.learning.current = detailPlan(id: 'p2', title: 'Rencana terbaru');
    await render(tester, id: 'p2');
    old.complete(detailPlan());
    await tester.pumpAndSettle();
    expect(find.text('Rencana terbaru'), findsOneWidget);
    expect(find.text('Rencana belajar Oktober'), findsNothing);
    final closing = Completer<LearningPlan>();
    fixture.learning.respondPlan = (_) => closing.future;
    await render(tester, id: 'p3', settle: false);
    await tester.pumpWidget(const SizedBox.shrink());
    closing.complete(detailPlan(id: 'p3'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'long content at 320px/large text remains scrollable through add action',
    (tester) async {
      viewport(tester, const Size(320, 568));
      fixture.learning.current = detailPlan(
        title: 'Rencana belajar siswa dengan judul yang cukup panjang',
        subject: 'Bidang belajar dengan nama yang cukup panjang',
        targets: List.generate(12, (index) => planDetailTarget('t$index')),
      );
      fixture.students.current = detailStudent(
        name: 'Nama siswa yang cukup panjang',
        status: 'archived',
      );
      await render(tester, scale: 2);
      final scrollable = find
          .descendant(
            of: key('detail-scroll-p1'),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        key('add-target'),
        400,
        maxScrolls: 50,
        scrollable: scrollable,
      );
      expect(key('add-target').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
