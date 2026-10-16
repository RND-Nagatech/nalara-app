import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/lesson_reports/domain/entities/lesson_report.dart';
import 'package:nalara/features/lesson_reports/domain/repositories/reports_repository.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/entities/session_overview.dart';
import 'package:nalara/features/schedules/domain/repositories/schedules_repository.dart';
import 'package:nalara/features/schedules/domain/usecases/load_session_overview.dart';
import 'package:nalara/features/schedules/presentation/pages/schedules_pages.dart';
import 'package:nalara/features/schedules/presentation/widgets/session_detail_style.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/domain/teaching_catalog_changes.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/widgets/nalara_dropdown.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

Lesson _lesson({
  String status = 'scheduled',
  String attendance = 'pending',
  String studentName = 'Alya',
  String subjectName = 'Piano',
}) => Lesson(
  id: 'session-1',
  scheduleId: 'schedule-1',
  studentId: 'student-1',
  subjectId: 'subject-1',
  startAt: DateTime.utc(2026, 10, 15, 8, 18),
  endAt: DateTime.utc(2026, 10, 15, 9, 18),
  status: status,
  attendance: attendance,
  studentName: studentName,
  subjectName: subjectName,
);

class _Schedules implements SchedulesRepository {
  Lesson lesson = _lesson();
  Object? error;
  final sessionsRead = <String>[];
  final seriesRead = <String>[];
  final writes = <(String, String)>[];
  Completer<void>? pendingWrite;

  @override
  Future<Lesson> session(String id) async {
    sessionsRead.add(id);
    if (error != null) throw error!;
    return lesson;
  }

  @override
  Future<Schedule> schedule(String id) async {
    seriesRead.add(id);
    return Schedule(
      id: id,
      studentId: lesson.studentId,
      subjectId: lesson.subjectId,
      timezone: 'Asia/Makassar',
      recurrence: 'weekly',
      status: 'scheduled',
      repeatCount: 4,
      startAt: lesson.startAt,
      endAt: lesson.endAt,
    );
  }

  @override
  Future<void> attendance(String id, String status) async {
    writes.add((id, status));
    if (pendingWrite != null) await pendingWrite!.future;
    if (error != null) throw error!;
    lesson = _lesson(status: 'completed', attendance: status);
  }

  @override
  Future<void> cancelSession(String id) async {
    writes.add((id, 'cancelled'));
    lesson = _lesson(status: 'cancelled', attendance: 'cancelled');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reports implements ReportsRepository {
  final sessionIds = <String?>[];
  final records = <LessonReport>[];
  Object? error;

  @override
  Future<PageResult<LessonReport>> list({
    int page = 1,
    String? studentId,
    String? status,
    String? sessionId,
  }) async {
    sessionIds.add(sessionId);
    if (error != null) throw error!;
    return PageResult(
      items: records,
      total: records.length,
      page: page,
      limit: 20,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Schedules schedules;
  late _Reports reports;
  late LoadSessionOverview load;
  late TeachingCatalogChanges changes;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    schedules = _Schedules();
    reports = _Reports();
    load = LoadSessionOverview(schedules, reports);
    changes = TeachingCatalogChanges();
    getIt.registerSingleton<SchedulesRepository>(schedules);
    getIt.registerSingleton(load);
    getIt.registerSingleton(changes, dispose: (value) => value.close());
  });
  tearDown(() => getIt.reset());

  Finder key(String id) => find.byKey(ValueKey('session-$id'));
  void viewport(WidgetTester tester, {Size size = const Size(430, 1100)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(WidgetTester tester, {double scale = 1}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const SessionDetailPage(id: 'session-1'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> drainNotice(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  test(
    'overview keeps canonical names, real series timezone and scoped report snapshot',
    () async {
      final data = await load('session-1');
      expect(schedules.sessionsRead, ['session-1']);
      expect(schedules.seriesRead, ['schedule-1']);
      expect(reports.sessionIds, ['session-1']);
      expect(data.lesson.studentName, 'Alya');
      expect(data.lesson.subjectName, 'Piano');
      expect(data.schedule.timezone, 'Asia/Makassar');
      expect(() => data.reports.clear(), throwsUnsupportedError);
    },
  );

  test(
    'overview forwards a report backend failure without wrapping its message',
    () async {
      const failure = AppFailure('Akses laporan ditolak');
      reports.error = failure;
      await expectLater(load('session-1'), throwsA(same(failure)));
    },
  );

  testWidgets('themed cards show live names, timezone and saved attendance', (
    tester,
  ) async {
    viewport(tester);
    schedules.lesson = _lesson(status: 'completed', attendance: 'excused');
    await render(tester);
    expect(find.text('Detail sesi'), findsOneWidget);
    expect(find.text('Alya'), findsOneWidget);
    expect(find.text('Piano'), findsOneWidget);
    expect(find.text('ROBI'), findsNothing);
    expect(find.text('Waktu (Asia/Makassar)'), findsOneWidget);
    expect(find.text('15 Okt 2026 · 16:18 – 17:18'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      SessionDetailStyle.cream,
    );
    expect(
      tester.widget<Image>(key('artwork')).image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'asset',
        'assets/Icon/Icon lainnya.png',
      ),
    );
    expect(
      tester.widget<NalaraDropdown<String>>(key('attendance')).value,
      'excused',
    );
    expect(
      tester.widget<NalaraDropdown<String>>(key('attendance')).enabled,
      isFalse,
    );
    expect(
      tester.widget<FilledButton>(key('save-attendance')).onPressed,
      isNull,
    );
    expect(find.text('Presensi sudah disimpan dan dikunci.'), findsOneWidget);
    expect(find.text('Status Izin tidak dapat diubah lagi.'), findsOneWidget);
    expect(key('manage-card'), findsNothing);
  });

  testWidgets(
    'pending defaults to Hadir and a write disables all session actions',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(
        tester.widget<NalaraDropdown<String>>(key('attendance')).value,
        'present',
      );
      schedules.pendingWrite = Completer<void>();
      await tester.ensureVisible(key('save-attendance'));
      await tester.tap(key('save-attendance'));
      await tester.pump();
      expect(schedules.writes, [('session-1', 'present')]);
      expect(
        tester.widget<FilledButton>(key('save-attendance')).onPressed,
        isNull,
      );
      expect(tester.widget<IconButton>(key('back')).onPressed, isNull);
      schedules.pendingWrite!.complete();
      await tester.pumpAndSettle();
      await drainNotice(tester);
      expect(schedules.sessionsRead.length, 2);
    },
  );

  testWidgets(
    'cancel requires confirmation then hides editing and report creation',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tap(tester, key('cancel'));
      expect(schedules.writes, isEmpty);
      await tap(tester, find.text('Batal'));
      expect(schedules.writes, isEmpty);
      await tap(tester, key('cancel'));
      await tap(tester, find.text('Lanjutkan'));
      await drainNotice(tester);
      expect(schedules.writes, [('session-1', 'cancelled')]);
      expect(key('manage-card'), findsNothing);
      expect(key('save-attendance'), findsNothing);
      await tester.scrollUntilVisible(key('reports-card'), 200);
      expect(key('create-report'), findsNothing);
      expect(
        find.text('Belum ada laporan untuk sesi yang dibatalkan ini.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'raw loading error can retry, catalog refresh updates linked names',
    (tester) async {
      viewport(tester);
      schedules.error = const AppFailure('Sesi tidak tersedia');
      await render(tester);
      expect(find.text('Sesi tidak tersedia'), findsOneWidget);
      expect(key('summary-card'), findsNothing);
      schedules.error = null;
      await tap(tester, key('retry'));
      schedules.lesson = _lesson(subjectName: 'Piano klasik');
      changes.notifyChanged();
      await tester.pumpAndSettle();
      expect(find.text('Piano klasik'), findsOneWidget);
    },
  );

  testWidgets('narrow screen and large text stay scrollable without overflow', (
    tester,
  ) async {
    viewport(tester, size: const Size(320, 640));
    schedules.lesson = _lesson(
      studentName: 'Alya dengan nama lengkap yang panjang',
      subjectName: 'Piano klasik dan latihan membaca notasi musik',
    );
    await render(tester, scale: 1.8);
    await tester.scrollUntilVisible(key('create-report'), 200);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'student, series, edit and report links preserve routes and refresh on return',
    (tester) async {
      viewport(tester);
      final destinations = {
        'student': '/teacher/students/student-1',
        'series': '/teacher/schedule/schedule-1',
        'reschedule': '/teacher/sessions/session-1/edit',
        'create-report': '/teacher/reports/new',
      };
      final router = GoRouter(
        initialLocation: '/teacher/sessions/session-1',
        routes: [
          GoRoute(
            path: '/teacher/sessions/session-1',
            builder: (_, _) => const SessionDetailPage(id: 'session-1'),
          ),
          for (final destination in destinations.values)
            GoRoute(
              path: destination,
              builder: (_, state) => Scaffold(
                body: Text(
                  'Tujuan ${state.uri.path} ${state.uri.queryParameters['sessionId'] ?? ''}',
                ),
              ),
            ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      for (final entry in destinations.entries) {
        final before = schedules.sessionsRead.length;
        await tap(tester, key(entry.key));
        expect(find.textContaining('Tujuan ${entry.value}'), findsOneWidget);
        if (entry.key == 'create-report') {
          expect(find.textContaining('session-1'), findsOneWidget);
        }
        router.pop();
        await tester.pumpAndSettle();
        expect(schedules.sessionsRead.length, before + 1);
      }
    },
  );

  test(
    'an overview list does not retain a mutable repository list reference',
    () async {
      final data = await load('session-1');
      final second = SessionOverview(
        lesson: data.lesson,
        schedule: data.schedule,
        reports: reports.records,
      );
      expect(identical(second.reports, reports.records), isFalse);
    },
  );
}
