import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/entities/schedule_period.dart';
import 'package:nalara/features/schedules/domain/usecases/load_schedule_agenda.dart';
import 'package:nalara/features/schedules/presentation/bloc/schedule_agenda_cubit.dart';
import 'package:nalara/features/schedules/presentation/pages/schedules_pages.dart';
import 'package:nalara/features/schedules/presentation/widgets/agenda_style.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'schedule_fixtures.dart';

void main() {
  late ScheduleRepositoryFake repository;
  late ScheduleAgendaCubit cubit;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    repository = ScheduleRepositoryFake();
    getIt.registerFactory<ScheduleAgendaCubit>(() {
      cubit = ScheduleAgendaCubit(
        LoadScheduleAgenda(repository),
        clock: () => DateTime.utc(2026, 10, 14, 19),
      );
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
    String period = 'day',
    DateTime? date,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 24, bottom: 18),
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: SchedulesPage(
          initialPeriod: period,
          initialDate: date ?? DateTime(2026, 10, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder body() =>
      find.byKey(ValueKey('agenda-body-${cubit.state.period.name}'));
  Finder inside(Finder finder) => find.descendant(of: body(), matching: finder);
  Finder dateKey(String period, DateTime date) =>
      find.byKey(ValueKey('agenda-day-$period-${date.toIso8601String()}'));
  Future<GoRouter> routed(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/teacher/schedule',
      routes: [
        GoRoute(
          path: '/teacher/schedule',
          builder: (_, _) => SchedulesPage(initialDate: DateTime(2026, 10, 15)),
        ),
        GoRoute(
          path: '/teacher/schedule/new',
          builder: (_, _) => const Scaffold(body: Text('Form jadwal')),
        ),
        GoRoute(
          path: '/teacher/sessions/a',
          builder: (_, _) => const Scaffold(body: Text('Detail sesi')),
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
    'daily mockup uses real weekday/date, full week strip and the original empty asset',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Jadwal les'), findsOneWidget);
      expect(find.text('Atur dan kelola sesi les Anda'), findsOneWidget);
      expect(
        tester.getRect(find.text('Jadwal les')).top,
        greaterThanOrEqualTo(24),
      );
      expect(inside(find.text('Kamis, 15 Oktober 2026')), findsOneWidget);
      for (var day = 12; day <= 18; day++) {
        expect(
          inside(dateKey('day', DateTime.utc(2026, 10, day))),
          findsOneWidget,
        );
      }
      expect(
        tester
            .widget<TabBar>(find.byKey(const ValueKey('agenda-tabs')))
            .controller!
            .index,
        0,
      );
      expect(
        inside(find.text('Belum ada sesi pada tanggal ini.')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Image>(
              inside(find.byKey(const ValueKey('agenda-empty-artwork-day'))),
            )
            .image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'asset',
          AgendaStyle.emptyArtwork,
        ),
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(repository.calls.single.from, DateTime.utc(2026, 10, 14, 17));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'tap/swipe both directions synchronize the period, indicator and backend range',
    (tester) async {
      viewport(tester);
      await render(tester);
      final view = find.byKey(const ValueKey('agenda-tab-view'));
      await tester.drag(view, const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(cubit.state.period, SchedulePeriod.week);
      expect(inside(find.text('12–18 Oktober 2026')), findsOneWidget);
      expect(
        inside(find.text('Belum ada sesi pada minggu ini.')),
        findsOneWidget,
      );
      expect(repository.calls.last.from, DateTime.utc(2026, 10, 11, 17));
      await tester.drag(view, const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(cubit.state.period, SchedulePeriod.month);
      expect(
        inside(find.byKey(const ValueKey('agenda-month-grid'))),
        findsOneWidget,
      );
      expect(inside(find.text('Oktober 2026')), findsOneWidget);
      expect(repository.calls.last.from, DateTime.utc(2026, 9, 30, 17));
      await tester.drag(view, const Offset(350, 0));
      await tester.pumpAndSettle();
      await tester.drag(view, const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(cubit.state.period, SchedulePeriod.day);
      expect(repository.calls, hasLength(3));
      await tester.tap(find.byKey(const ValueKey('agenda-tab-month')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TabBar>(find.byKey(const ValueKey('agenda-tabs')))
            .controller!
            .index,
        2,
      );
    },
  );
  testWidgets(
    'daily arrows advance one day and choosing a date queries exactly that day',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tester.tap(inside(find.byKey(const ValueKey('agenda-next-day'))));
      await tester.pumpAndSettle();
      expect(cubit.state.date, DateTime.utc(2026, 10, 16));
      expect(inside(find.text('Jumat, 16 Oktober 2026')), findsOneWidget);
      await tester.tap(inside(dateKey('day', DateTime.utc(2026, 10, 18))));
      await tester.pumpAndSettle();
      expect(repository.calls.last.from, DateTime.utc(2026, 10, 17, 17));
      expect(inside(find.text('Minggu, 18 Oktober 2026')), findsOneWidget);
    },
  );
  testWidgets(
    'weekly mode includes weekend sessions, groups dates, and arrows move seven days',
    (tester) async {
      viewport(tester);
      repository.records = [
        agendaLesson('a', 16),
        agendaLesson('b', 18),
        agendaLesson('outside', 19),
      ];
      await render(tester, period: 'week');
      expect(inside(find.text('Pelajaran a')), findsOneWidget);
      expect(inside(find.text('Pelajaran b')), findsOneWidget);
      expect(inside(find.text('Pelajaran outside')), findsNothing);
      expect(inside(find.text('Minggu, 18 Oktober 2026')), findsOneWidget);
      expect(
        inside(find.byKey(const ValueKey('agenda-empty-artwork-week'))),
        findsNothing,
      );
      final count = repository.calls.length;
      await tester.tap(inside(dateKey('week', DateTime.utc(2026, 10, 18))));
      await tester.pumpAndSettle();
      expect(repository.calls, hasLength(count));
      await tester.tap(inside(find.byKey(const ValueKey('agenda-next-week'))));
      await tester.pumpAndSettle();
      expect(inside(find.text('19–25 Oktober 2026')), findsOneWidget);
      expect(inside(find.text('Pelajaran outside')), findsOneWidget);
    },
  );
  testWidgets(
    'monthly grid includes every leap-day date and tapping one switches to daily agenda',
    (tester) async {
      viewport(tester);
      await render(tester, period: 'month', date: DateTime(2028, 2, 15));
      for (var day = 1; day <= 29; day++) {
        expect(
          inside(dateKey('month', DateTime.utc(2028, 2, day))),
          findsOneWidget,
        );
      }
      expect(inside(dateKey('month', DateTime.utc(2028, 3, 1))), findsNothing);
      await tester.tap(inside(dateKey('month', DateTime.utc(2028, 2, 29))));
      await tester.pumpAndSettle();
      expect(cubit.state.period, SchedulePeriod.day);
      expect(cubit.state.date, DateTime.utc(2028, 2, 29));
      expect(
        tester
            .widget<TabBar>(find.byKey(const ValueKey('agenda-tabs')))
            .controller!
            .index,
        0,
      );
      expect(repository.calls.last.from, DateTime.utc(2028, 2, 28, 17));
    },
  );
  testWidgets(
    'month arrows clamp January 31 to February and restore March 31',
    (tester) async {
      viewport(tester);
      await render(tester, period: 'month', date: DateTime(2026, 1, 31));
      await tester.tap(inside(find.byKey(const ValueKey('agenda-next-month'))));
      await tester.pumpAndSettle();
      expect(cubit.state.date, DateTime.utc(2026, 2, 28));
      expect(inside(dateKey('month', DateTime.utc(2026, 2, 29))), findsNothing);
      await tester.tap(inside(find.byKey(const ValueKey('agenda-next-month'))));
      await tester.pumpAndSettle();
      expect(cubit.state.date, DateTime.utc(2026, 3, 31));
    },
  );
  testWidgets(
    'calendar caption opens the date picker and applies a selected calendar date',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tester.tap(
        inside(find.byKey(const ValueKey('agenda-caption-day'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      Navigator.of(
        tester.element(find.byType(DatePickerDialog)),
      ).pop(DateTime(2026, 11, 3));
      await tester.pumpAndSettle();
      expect(cubit.state.date, DateTime.utc(2026, 11, 3));
      expect(repository.calls.last.from, DateTime.utc(2026, 11, 2, 17));
    },
  );
  testWidgets(
    'backend loading/errors never masquerade as an empty agenda, retry keeps controls',
    (tester) async {
      viewport(tester);
      repository.error = const AppFailure(
        'Jadwal tidak dapat dimuat. Coba kembali.',
        code: 'UNAVAILABLE',
      );
      await render(tester);
      expect(
        inside(find.text('Jadwal tidak dapat dimuat. Coba kembali.')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('agenda-tabs')), findsOneWidget);
      expect(
        inside(find.byKey(const ValueKey('agenda-empty-artwork-day'))),
        findsNothing,
      );
      repository.error = null;
      await tester.tap(inside(find.text('Coba lagi')));
      await tester.pumpAndSettle();
      expect(
        inside(find.byKey(const ValueKey('agenda-empty-artwork-day'))),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'pending initial API response has no dummy sessions or empty illustration',
    (tester) async {
      viewport(tester);
      final gate = Completer<PageResult<Lesson>>();
      repository.respond = (_) => gate.future;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: SchedulesPage(initialDate: DateTime(2026, 10, 15)),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('agenda-empty-artwork-day')),
        findsNothing,
      );
      gate.complete(const PageResult(items: [], total: 0, page: 1, limit: 30));
      await tester.pumpAndSettle();
      expect(
        inside(find.byKey(const ValueKey('agenda-empty-artwork-day'))),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'empty CTA opens existing create form and refreshes the selected range on return',
    (tester) async {
      viewport(tester);
      final router = await routed(tester);
      await tester.ensureVisible(
        inside(find.byKey(const ValueKey('agenda-add-empty-day'))),
      );
      await tester.tap(
        inside(find.byKey(const ValueKey('agenda-add-empty-day'))),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/teacher/schedule/new');
      repository.records.add(agendaLesson('a', 15));
      router.pop();
      await tester.pumpAndSettle();
      expect(inside(find.text('Pelajaran a')), findsOneWidget);
      expect(find.byKey(const ValueKey('agenda-add')), findsOneWidget);
      await tester.tap(inside(find.text('Pelajaran a')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/teacher/sessions/a');
      router.pop();
      await tester.pumpAndSettle();
      expect(repository.calls, hasLength(3));
    },
  );
  testWidgets('load more appends results and refresh returns to page one', (
    tester,
  ) async {
    viewport(tester);
    repository.limit = 1;
    repository.records = [
      agendaLesson('a', 15),
      agendaLesson('b', 15, hour: 4),
    ];
    await render(tester);
    await tester.ensureVisible(
      inside(find.byKey(const ValueKey('agenda-load-more-day'))),
    );
    await tester.tap(
      inside(find.byKey(const ValueKey('agenda-load-more-day'))),
    );
    await tester.pumpAndSettle();
    expect(inside(find.text('Pelajaran a')), findsOneWidget);
    expect(inside(find.text('Pelajaran b')), findsOneWidget);
    expect(repository.calls.last.page, 2);
    await tester.ensureVisible(find.byKey(const ValueKey('agenda-refresh')));
    await tester.tap(find.byKey(const ValueKey('agenda-refresh')));
    await tester.pumpAndSettle();
    expect(repository.calls.last.page, 1);
    expect(inside(find.text('Pelajaran a')), findsOneWidget);
  });
  testWidgets(
    '320px monthly calendar and large text remain scrollable without overflow',
    (tester) async {
      viewport(tester, const Size(320, 640));
      await render(tester, period: 'month', scale: 2);
      expect(
        tester.getRect(find.text('Jadwal les')).top,
        greaterThanOrEqualTo(24),
      );
      final inner = find
          .descendant(of: body(), matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        inside(find.byKey(const ValueKey('agenda-add-empty-month'))),
        250,
        scrollable: inner,
      );
      expect(
        inside(find.byKey(const ValueKey('agenda-add-empty-month'))),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
