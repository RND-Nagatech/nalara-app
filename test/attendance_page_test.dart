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
import 'package:nalara/features/schedules/presentation/widgets/attendance_lesson_card.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'schedule_fixtures.dart';

Lesson attendanceLesson(
  String id, {
  String attendance = 'pending',
  String status = 'scheduled',
  String? name,
}) {
  final source = agendaLesson(id, 15);
  return Lesson(
    id: source.id,
    scheduleId: source.scheduleId,
    studentId: source.studentId,
    subjectId: source.subjectId,
    startAt: source.startAt,
    endAt: source.endAt,
    studentName: name ?? source.studentName,
    subjectName: source.subjectName,
    studentGrade: source.studentGrade,
    status: status,
    attendance: attendance,
  );
}

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
  tearDown(() => getIt.reset());
  Finder key(String id) => find.byKey(ValueKey('attendance-$id'));
  Finder active(Finder finder) => find.descendant(
    of: key('body-${cubit.state.period.name}'),
    matching: finder,
  );

  void viewport(WidgetTester tester, [Size size = const Size(430, 1000)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(
    WidgetTester tester, {
    String? period,
    double scale = 1,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 28, bottom: 20),
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: SchedulesPage(
          attendance: true,
          initialDate: DateTime(2026, 10, 15),
          initialPeriod: period,
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cream header and shared underline tabs preserve weekly default and scoped data',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Presensi'), findsOneWidget);
      expect(tester.getRect(key('back')).top, greaterThanOrEqualTo(28));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AgendaStyle.cream,
      );
      expect(find.byType(SegmentedButton<String>), findsNothing);
      final tabs = tester.widget<TabBar>(key('tabs'));
      expect(tabs.indicatorSize, TabBarIndicatorSize.tab);
      expect(tabs.indicatorColor, AgendaStyle.green);
      expect(tabs.controller!.index, 1);
      expect(cubit.state.period, SchedulePeriod.week);
      expect(repository.calls.single.from, DateTime.utc(2026, 10, 11, 17));
      expect(
        repository.calls.single.to,
        DateTime.utc(2026, 10, 18, 16, 59, 59, 999),
      );
      expect(
        tester.widget<Image>(active(key('empty-artwork-week'))).image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'asset',
          AgendaStyle.emptyArtwork,
        ),
      );
      expect(
        tester.getSize(active(key('empty-artwork-week'))).width,
        lessThanOrEqualTo(240),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tap and swipe synchronize periods, calendar and cached backend windows',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tester.drag(key('tab-view'), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(cubit.state.period, SchedulePeriod.month);
      expect(
        active(find.byKey(const ValueKey('agenda-month-grid'))),
        findsOneWidget,
      );
      expect(repository.calls.last.from, DateTime.utc(2026, 9, 30, 17));
      await tester.drag(key('tab-view'), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(cubit.state.period, SchedulePeriod.week);
      await tap(tester, key('tab-day'));
      expect(cubit.state.period, SchedulePeriod.day);
      expect(repository.calls.last.from, DateTime.utc(2026, 10, 14, 17));
      expect(tester.widget<TabBar>(key('tabs')).controller!.index, 0);
      expect(repository.calls.length, 3);
    },
  );

  testWidgets(
    'month date opens daily attendance and calendar arrows use the current period',
    (tester) async {
      viewport(tester);
      await render(tester, period: 'month');
      await tap(
        tester,
        active(
          find.byKey(
            const ValueKey('agenda-day-month-2026-10-18T00:00:00.000Z'),
          ),
        ),
      );
      expect(cubit.state.period, SchedulePeriod.day);
      expect(cubit.state.date, DateTime.utc(2026, 10, 18));
      await tap(tester, active(find.byKey(const ValueKey('agenda-next-day'))));
      expect(cubit.state.date, DateTime.utc(2026, 10, 19));
      expect(repository.calls.last.from, DateTime.utc(2026, 10, 18, 17));
    },
  );

  testWidgets(
    'cards show real student, subject, attendance and session status, without write controls',
    (tester) async {
      viewport(tester);
      repository.records = [
        attendanceLesson('pending'),
        attendanceLesson('present', attendance: 'present', status: 'completed'),
        attendanceLesson('absent', attendance: 'absent', status: 'completed'),
        attendanceLesson('excused', attendance: 'excused', status: 'completed'),
        attendanceLesson(
          'cancelled',
          attendance: 'cancelled',
          status: 'cancelled',
        ),
      ];
      await render(tester, period: 'day');
      expect(active(find.byType(AttendanceLessonCard)), findsWidgets);
      expect(active(find.text('Alya pending')), findsOneWidget);
      expect(active(find.text('Pelajaran pending · Kelas 5')), findsOneWidget);
      for (final entry in {
        'pending': 'Belum dicatat',
        'present': 'Hadir',
        'absent': 'Tidak hadir',
        'excused': 'Izin',
        'cancelled': 'Dibatalkan',
      }.entries) {
        final status = active(key('status-${entry.key}'));
        final scrollable = find
            .descendant(of: key('body-day'), matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(status, 180, scrollable: scrollable);
        expect(
          find.descendant(of: status, matching: find.text(entry.value)),
          findsOneWidget,
        );
      }
      expect(find.text('Simpan presensi'), findsNothing);
    },
  );

  testWidgets(
    'loading and raw errors are not empty, including refreshing a cached empty list',
    (tester) async {
      viewport(tester);
      final initial = Completer<PageResult<Lesson>>();
      repository.respond = (_) => initial.future;
      await render(tester, settle: false);
      expect(active(key('empty-artwork-week')), findsNothing);
      initial.completeError(const AppFailure('Presensi belum dapat dimuat'));
      await tester.pumpAndSettle();
      expect(active(find.text('Presensi belum dapat dimuat')), findsOneWidget);
      expect(active(key('empty-artwork-week')), findsNothing);
      repository.respond = null;
      await tap(tester, active(find.text('Coba lagi')));
      expect(active(key('empty-artwork-week')), findsOneWidget);
      final next = Completer<PageResult<Lesson>>();
      repository.respond = (_) => next.future;
      await tester.tap(key('refresh'));
      await tester.pump();
      expect(active(key('empty-artwork-week')), findsNothing);
      next.complete(const PageResult(items: [], total: 0, page: 1, limit: 30));
      await tester.pumpAndSettle();
      expect(active(key('empty-artwork-week')), findsOneWidget);
    },
  );

  testWidgets(
    'load more is server-owned and refresh returns the selected period to page one',
    (tester) async {
      viewport(tester);
      repository.limit = 1;
      repository.records = [attendanceLesson('a'), attendanceLesson('b')];
      await render(tester);
      await tap(tester, active(key('load-more-week')));
      expect(active(find.text('Alya a')), findsOneWidget);
      expect(active(find.text('Alya b')), findsOneWidget);
      expect(repository.calls.last.page, 2);
      await tap(tester, key('refresh'));
      expect(repository.calls.last.page, 1);
      expect(cubit.state.period, SchedulePeriod.week);
    },
  );

  testWidgets(
    'detail/create navigation refreshes attendance and direct back falls back to More',
    (tester) async {
      viewport(tester);
      final router = GoRouter(
        initialLocation: '/teacher/attendance',
        routes: [
          GoRoute(
            path: '/teacher/attendance',
            builder: (_, _) => SchedulesPage(
              attendance: true,
              initialDate: DateTime(2026, 10, 15),
            ),
          ),
          for (final route in [
            '/teacher/schedule/new',
            '/teacher/sessions/a',
            '/teacher/more',
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
      await tap(tester, active(key('add-empty-week')));
      expect(find.text('Tujuan /teacher/schedule/new'), findsOneWidget);
      repository.records = [attendanceLesson('a')];
      router.pop();
      await tester.pumpAndSettle();
      await tap(tester, active(key('session-a')));
      expect(find.text('Tujuan /teacher/sessions/a'), findsOneWidget);
      repository.records = [
        attendanceLesson('a', attendance: 'present', status: 'completed'),
      ];
      router.pop();
      await tester.pumpAndSettle();
      expect(active(find.text('Hadir')), findsOneWidget);
      await tap(tester, key('back'));
      expect(find.text('Tujuan /teacher/more'), findsOneWidget);
    },
  );

  for (final empty in [true, false]) {
    testWidgets(
      'empty=$empty stays scrollable on a narrow screen with large text',
      (tester) async {
        viewport(tester, const Size(320, 640));
        if (!empty) {
          repository.records = [
            attendanceLesson(
              'long',
              name:
                  'Nama siswa yang sangat panjang untuk menguji pembungkusan teks',
            ),
          ];
        }
        await render(tester, period: 'month', scale: 1.8);
        final scrollable = find
            .descendant(
              of: key('body-month'),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          active(empty ? key('add-empty-month') : key('status-long')),
          220,
          scrollable: scrollable,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
