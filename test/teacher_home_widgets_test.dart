import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/app.dart';
import 'package:nalara/features/dashboard/domain/entities/dashboard.dart';
import 'package:nalara/features/dashboard/domain/usecases/load_teacher_home.dart';
import 'package:nalara/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:nalara/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nalara/features/dashboard/presentation/widgets/home_lesson_card.dart';
import 'package:nalara/features/dashboard/presentation/widgets/home_style.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/repositories/schedules_repository.dart';
import 'package:nalara/features/schedules/domain/usecases/load_schedule_agenda.dart';
import 'package:nalara/features/schedules/presentation/bloc/schedule_agenda_cubit.dart';
import 'package:nalara/features/schedules/presentation/pages/schedules_pages.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'home_fixtures.dart';

class HomeSchedulesFake implements SchedulesRepository {
  final ranges = <({DateTime? from, DateTime? to})>[];
  @override
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
    String? studentId,
    String? scheduleId,
  }) async {
    ranges.add((from: from, to: to));
    return PageResult(items: const [], page: page, limit: 30, total: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late HomeRepositoryFake repository;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    repository = HomeRepositoryFake(homeOverview());
    getIt.registerFactory(() => DashboardCubit(LoadTeacherHome(repository)));
    getIt.registerFactory(
      () =>
          ScheduleAgendaCubit(LoadScheduleAgenda(getIt<SchedulesRepository>())),
    );
  });
  tearDown(() async => getIt.reset());

  void viewport(WidgetTester tester, [Size size = const Size(430, 900)]) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(
    WidgetTester tester, {
    double scale = 1,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale), padding: padding),
          child: child!,
        ),
        home: const DashboardPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  GoRouter homeRouter() => GoRouter(
    initialLocation: '/teacher/home',
    routes: [
      GoRoute(path: '/teacher/home', builder: (_, _) => const DashboardPage()),
      for (final path in [
        '/teacher/profile',
        '/teacher/notifications',
        '/teacher/reports',
        '/teacher/students',
        '/teacher/sessions/a',
        '/teacher/schedule/new',
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text(path)),
        ),
      GoRoute(
        path: '/teacher/schedule',
        builder: (_, state) => Scaffold(
          body: Text('Agenda: ${state.uri.queryParameters['date']}'),
        ),
      ),
    ],
  );
  Future<GoRouter> routed(WidgetTester tester) async {
    final router = homeRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'summary strip is exactly half above and half below Home artwork',
    (tester) async {
      viewport(tester);
      await render(tester);
      final artwork = tester.getRect(
        find.byKey(const ValueKey('home-artwork')),
      );
      final strip = tester.getRect(
        find.byKey(const ValueKey('home-summary-strip')),
      );
      expect(strip.center.dy, closeTo(artwork.bottom, .5));
      expect(strip.top, lessThan(artwork.bottom));
      expect(strip.bottom, greaterThan(artwork.bottom));
      for (final stat in [
        ('home-active-students', '27', HomeStyle.activeStudentsIcon),
        ('home-today-count', '9', HomeStyle.todayLessonsIcon),
        ('home-pending-reports', '4', HomeStyle.pendingReportsIcon),
      ]) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey(stat.$1)),
            matching: find.text(stat.$2),
          ),
          findsOneWidget,
        );
        final image = tester.widget<Image>(
          find.descendant(
            of: find.byKey(ValueKey(stat.$1)),
            matching: find.byType(Image),
          ),
        );
        expect((image.image as AssetImage).assetName, stat.$3);
      }
      expect(find.text('Rabu, 14 Oktober 2026'), findsOneWidget);
      expect(find.text('Selamat pagi,'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('home-brand')))
            .style
            ?.fontFamily,
        'NalaraLora',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('home-teacher-name')))
            .style
            ?.fontFamily,
        'NalaraLora',
      );
      expect(
        tester.widget<Image>(find.byKey(const ValueKey('home-artwork'))).image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'asset',
          HomeStyle.artwork,
        ),
      );
      final brand = tester.getRect(find.byKey(const ValueKey('home-brand')));
      expect(brand.bottom, lessThanOrEqualTo(artwork.top));
      expect(
        tester
            .widget<Badge>(
              find.byKey(const ValueKey('home-notification-badge')),
            )
            .isLabelVisible,
        isTrue,
      );
      expect(repository.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'only three time-ordered real lessons are shown, with names/grades and no subject icons',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.byType(HomeLessonCard), findsNWidgets(3));
      expect(
        tester
            .widgetList<HomeLessonCard>(find.byType(HomeLessonCard))
            .map((card) => card.lesson.id),
        ['a', 'b', 'c'],
      );
      expect(find.text('Pelajaran d'), findsNothing);
      expect(find.text('Siswa a · Kelas 6'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
      expect(find.byIcon(Icons.headphones), findsNothing);
      expect(find.byIcon(Icons.science_outlined), findsNothing);
      expect(find.text('Aksi cepat'), findsNothing);
      expect(find.byKey(const ValueKey('home-empty-schedule')), findsNothing);
    },
  );
  for (final scale in [1.5, 2.0]) {
    testWidgets(
      '320px width, SafeArea and long teacher name at text scale $scale',
      (tester) async {
        viewport(tester, const Size(320, 760));
        repository.value = homeOverview(
          name: 'Ibu Guru Nara dengan nama yang sangat panjang',
        );
        await render(
          tester,
          scale: scale,
          padding: const EdgeInsets.only(top: 30, bottom: 22),
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('home-brand'))).top,
          greaterThanOrEqualTo(30),
        );
        final artwork = tester.getRect(
          find.byKey(const ValueKey('home-artwork')),
        );
        final strip = tester.getRect(
          find.byKey(const ValueKey('home-summary-strip')),
        );
        expect(strip.center.dy, closeTo(artwork.bottom, .5));
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('a')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Siswa a · Kelas 6'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'initial loading shows no fabricated zero counts, names or lessons',
    (tester) async {
      viewport(tester);
      final pending = Completer<TeacherDashboard>();
      repository.pending = pending.future;
      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const DashboardPage()),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('home-summary-strip')), findsNothing);
      expect(find.text('0'), findsNothing);
      expect(find.text('BU NARA 👋'), findsNothing);
      expect(find.byKey(const ValueKey('home-empty-artwork')), findsNothing);
      pending.complete(repository.value);
      await tester.pumpAndSettle();
      expect(find.text('BU NARA 👋'), findsOneWidget);
    },
  );
  testWidgets(
    'backend empty state has zeroes, no lessons and no notification dot',
    (tester) async {
      viewport(tester);
      repository.value = homeOverview(
        lessons: [],
        active: 0,
        today: 0,
        pending: 0,
        unread: 0,
      );
      await render(tester);
      expect(find.text('0'), findsNWidgets(3));
      expect(find.byType(HomeLessonCard), findsNothing);
      expect(find.text('Belum ada sesi hari ini.'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-empty-schedule')), findsOneWidget);
      expect(
        tester
            .widget<Image>(find.byKey(const ValueKey('home-empty-artwork')))
            .image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'asset',
          HomeStyle.emptyArtwork,
        ),
      );
      expect(
        find.text(
          'Mulai buat jadwal les untuk mengatur kegiatan mengajar Anda.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Buat jadwal les'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Badge>(
              find.byKey(const ValueKey('home-notification-badge')),
            )
            .isLabelVisible,
        isFalse,
      );
    },
  );
  testWidgets(
    'empty calendar action opens the existing schedule creation route',
    (tester) async {
      viewport(tester);
      repository.value = homeOverview(
        lessons: [],
        active: 0,
        today: 0,
        pending: 0,
        unread: 0,
      );
      final router = await routed(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('home-create-schedule')),
      );
      await tester.tap(find.byKey(const ValueKey('home-create-schedule')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/teacher/schedule/new');
      expect(repository.calls, 1);
      router.pop();
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
    },
  );
  testWidgets(
    'empty calendar remains scrollable at 320px with large text and safe insets',
    (tester) async {
      viewport(tester, const Size(320, 760));
      repository.value = homeOverview(
        lessons: [],
        active: 0,
        today: 0,
        pending: 0,
        unread: 0,
      );
      await render(
        tester,
        scale: 2,
        padding: const EdgeInsets.only(top: 30, bottom: 22),
      );
      final artwork = tester.getRect(
        find.byKey(const ValueKey('home-artwork')),
      );
      expect(
        artwork.top,
        greaterThan(
          tester.getRect(find.byKey(const ValueKey('home-brand'))).bottom,
        ),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('home-brand'))).top,
        greaterThanOrEqualTo(30),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-create-schedule')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('home-empty-artwork')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('backend error message is displayed and retry fetches again', (
    tester,
  ) async {
    viewport(tester);
    repository.error = const AppFailure(
      'Data beranda tidak tersedia. Silakan coba lagi.',
      code: 'UNAVAILABLE',
    );
    await render(tester);
    expect(
      find.text('Data beranda tidak tersedia. Silakan coba lagi.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-summary-strip')), findsNothing);
    repository.error = null;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('BU NARA 👋'), findsOneWidget);
  });
  for (final destination in [
    ('home-profile', '/teacher/profile'),
    ('home-notifications', '/teacher/notifications'),
    ('home-pending-reports', '/teacher/reports'),
    ('a', '/teacher/sessions/a'),
  ]) {
    testWidgets(
      '${destination.$1} navigates and Home refreshes once on return',
      (tester) async {
        viewport(tester);
        final router = await routed(tester);
        await tester.ensureVisible(find.byKey(ValueKey(destination.$1)));
        await tester.tap(find.byKey(ValueKey(destination.$1)));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, destination.$2);
        expect(repository.calls, 1);
        repository.value = homeOverview(active: 28);
        router.pop();
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/teacher/home');
        expect(repository.calls, 2);
        expect(find.text('28'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'Lihat semua opens the server-date daily agenda, not the default week',
    (tester) async {
      viewport(tester);
      final router = await routed(tester);
      await tester.tap(find.byKey(const ValueKey('home-view-all')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/teacher/schedule');
      expect(router.state.uri.queryParameters, {
        'period': 'day',
        'date': '2026-10-14',
        'timezone': 'Asia/Jakarta',
      });
    },
  );
  testWidgets(
    'pull-to-refresh and app resume request new data without an extra initial fetch',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tester.drag(
        find.byKey(const ValueKey('home-scroll')),
        const Offset(0, 320),
      );
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repository.calls, 3);
    },
  );
  testWidgets(
    'persistent Home tab reloads on return, not while another tab resumes',
    (tester) async {
      viewport(tester);
      final router = GoRouter(
        initialLocation: '/teacher/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => TeacherShell(shell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/teacher/home',
                    builder: (_, _) => const DashboardPage(),
                  ),
                ],
              ),
              for (final path in [
                '/teacher/students',
                '/teacher/schedule',
                '/teacher/targets',
                '/teacher/more',
              ])
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: path,
                      builder: (_, _) => Scaffold(body: Text(path)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      expect(repository.calls, 1);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
        hasLength(5),
      );
      expect(
        NavigationBarTheme.of(
          tester.element(find.byType(NavigationBar)),
        ).height,
        78,
      );
      final roundedNav = tester.widget<ClipRRect>(
        find
            .ancestor(
              of: find.byType(NavigationBar),
              matching: find.byType(ClipRRect),
            )
            .first,
      );
      expect(
        roundedNav.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(22)),
      );
      await tester.tap(find.text('Siswa').last);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/teacher/students');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repository.calls, 1);
      repository.value = homeOverview(active: 30);
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      expect(find.text('30'), findsOneWidget);
      router.go('/teacher/home');
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
    },
  );
  testWidgets(
    'daily agenda computes each New York DST midnight independently',
    (tester) async {
      viewport(tester);
      final schedules = HomeSchedulesFake();
      getIt.registerSingleton<SchedulesRepository>(schedules);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: SchedulesPage(
            initialDate: DateTime(2026, 3, 8),
            initialPeriod: 'day',
            timezone: 'America/New_York',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(schedules.ranges.single.from, DateTime.utc(2026, 3, 8, 5));
      expect(
        schedules.ranges.single.to,
        DateTime.utc(2026, 3, 9, 4).subtract(const Duration(milliseconds: 1)),
      );
    },
  );
  testWidgets(
    'agenda route inputs reload the day when an existing schedule page was weekly',
    (tester) async {
      viewport(tester);
      final schedules = HomeSchedulesFake();
      getIt.registerSingleton<SchedulesRepository>(schedules);
      Future<void> agenda(String period, DateTime date) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: SchedulesPage(initialPeriod: period, initialDate: date),
          ),
        );
        await tester.pumpAndSettle();
      }

      await agenda('week', DateTime(2026, 10, 13));
      expect(schedules.ranges, hasLength(1));
      await agenda('day', DateTime(2026, 10, 14));
      expect(schedules.ranges, hasLength(2));
      expect(schedules.ranges.last.from, DateTime.utc(2026, 10, 13, 17));
      expect(
        schedules.ranges.last.to,
        DateTime.utc(
          2026,
          10,
          14,
          17,
        ).subtract(const Duration(milliseconds: 1)),
      );
      expect(
        tester
            .widget<TabBar>(find.byKey(const ValueKey('agenda-tabs')))
            .controller!
            .index,
        0,
      );
    },
  );
}
