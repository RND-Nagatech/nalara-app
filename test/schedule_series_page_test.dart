import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/repositories/schedules_repository.dart';
import 'package:nalara/features/schedules/presentation/pages/schedules_pages.dart';
import 'package:nalara/features/schedules/presentation/widgets/schedule_series_header.dart';
import 'package:nalara/features/schedules/presentation/widgets/schedule_series_summary.dart';
import 'package:nalara/features/schedules/presentation/widgets/session_detail_style.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

Schedule seriesFixture(
  String id, {
  String status = 'scheduled',
  String timezone = 'Asia/Jakarta',
  bool weekly = false,
  int count = 1,
}) => Schedule(
  id: id,
  studentId: 'student-$id',
  subjectId: 'subject-$id',
  timezone: timezone,
  recurrence: weekly ? 'weekly' : 'none',
  status: status,
  repeatCount: count,
  startAt: DateTime.utc(2026, 10, 15, 8, 18),
  endAt: DateTime.utc(2026, 10, 15, 9, 18),
);

class SeriesRepositoryFake implements SchedulesRepository {
  final reads = <String>[], cancelled = <String>[];
  final records = <String, Schedule>{
    's1': seriesFixture('s1'),
    's2': seriesFixture('s2', weekly: true, count: 8),
  };
  Object? error;
  Future<Schedule> Function(String)? read;
  Future<void> Function(String)? cancel;
  @override
  Future<Schedule> schedule(String id) async {
    reads.add(id);
    if (read != null) return await read!(id);
    if (error != null) throw error!;
    return records[id]!;
  }

  @override
  Future<void> cancelSeries(String scheduleId, String reason) async {
    cancelled.add(scheduleId);
    if (cancel != null) await cancel!(scheduleId);
    final old = records[scheduleId]!;
    records[scheduleId] = Schedule(
      id: old.id,
      studentId: old.studentId,
      subjectId: old.subjectId,
      timezone: old.timezone,
      recurrence: old.recurrence,
      status: 'cancelled',
      cancellationReason: reason,
      repeatCount: old.repeatCount,
      startAt: old.startAt,
      endAt: old.endAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SeriesRepositoryFake repository;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    repository = SeriesRepositoryFake();
    getIt.registerSingleton<SchedulesRepository>(repository);
  });
  tearDown(() => getIt.reset());

  Finder byId(String id) => find.byKey(ValueKey(id));
  void viewport(WidgetTester tester, [Size size = const Size(430, 1000)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(
    WidgetTester tester, {
    String id = 's1',
    double scale = 1,
    bool settle = true,
    GoRouter? router,
  }) async {
    Widget inset(BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.only(top: 28, bottom: 18),
        textScaler: TextScaler.linear(scale),
      ),
      child: child!,
    );
    await tester.pumpWidget(
      router == null
          ? MaterialApp(
              theme: buildAppTheme(),
              builder: inset,
              home: ScheduleDetailPage(id: id),
            )
          : MaterialApp.router(
              theme: buildAppTheme(),
              builder: inset,
              routerConfig: router,
            ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> tap(
    WidgetTester tester,
    Finder finder, {
    bool settle = true,
  }) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> confirmCancel(WidgetTester tester, {bool settle = true}) async {
    if (find.text('Konfirmasi pembatalan').evaluate().isEmpty) {
      await tap(tester, byId('series-cancel'));
      await tester.enterText(
        find.byKey(const ValueKey('cancel-reason')),
        'Guru berhenti mengajar sementara.',
      );
      await tap(tester, find.text('Lanjutkan'));
    }
    await tap(tester, find.text('Ya, batalkan seri'), settle: settle);
  }

  Future<void> dismissNotice(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  GoRouter router({String initial = '/teacher/schedule/s1'}) {
    final routes = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/teacher/schedule',
          builder: (_, _) => const Scaffold(body: Text('Agenda guru')),
          routes: [
            GoRoute(
              path: ':seriesId',
              builder: (_, state) =>
                  ScheduleDetailPage(id: state.pathParameters['seriesId']!),
              routes: [
                GoRoute(
                  path: 'sessions',
                  builder: (context, state) => Scaffold(
                    body: Column(
                      children: [
                        Text('Pertemuan ${state.pathParameters['seriesId']}'),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Kembali dari sesi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/other',
          builder: (_, _) => const Scaffold(body: Text('Halaman lain')),
        ),
      ],
    );
    addTearDown(routes.dispose);
    return routes;
  }

  testWidgets(
    'mockup cream/safe header, actual four summary rows, artwork and warning',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        SessionDetailStyle.cream,
      );
      expect(tester.getRect(byId('series-back')).top, greaterThanOrEqualTo(28));
      expect(find.text('Seri jadwal'), findsOneWidget);
      expect(
        find.text('Informasi jadwal berulang untuk pertemuan dengan siswa.'),
        findsOneWidget,
      );
      expect(
        (tester.widget<Image>(byId('series-header-artwork')).image
                as AssetImage)
            .assetName,
        ScheduleSeriesHeader.artwork,
      );
      expect(find.text('Pertemuan awal'), findsOneWidget);
      expect(find.text('15 Okt 2026 · 15:18'), findsOneWidget);
      expect(find.text('Satu pertemuan'), findsOneWidget);
      expect(find.text('Asia/Jakarta'), findsOneWidget);
      expect(find.text('Terjadwal'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(3));
      expect(byId('series-sessions'), findsOneWidget);
      expect(byId('series-cancel'), findsOneWidget);
      expect(
        find.text(
          'Semua sesi yang masih terjadwal dalam seri ini akan dibatalkan. Sesi yang sudah selesai tetap tersimpan.',
        ),
        findsOneWidget,
      );
      expect(repository.reads, ['s1']);
      expect(repository.cancelled, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'weekly count/timezone/status are taken from the schedule, not the mockup',
    (tester) async {
      viewport(tester);
      repository.records['s2'] = seriesFixture(
        's2',
        weekly: true,
        count: 12,
        timezone: 'Asia/Makassar',
      );
      await render(tester, id: 's2');
      expect(find.text('Mingguan · 12 pertemuan'), findsOneWidget);
      expect(find.text('15 Okt 2026 · 16:18'), findsOneWidget);
      expect(find.text('Asia/Makassar'), findsOneWidget);
      expect(repository.reads, ['s2']);
    },
  );

  testWidgets('loading/error/retry never shows fake schedule actions', (
    tester,
  ) async {
    viewport(tester);
    final pending = Completer<Schedule>();
    repository.read = (_) => pending.future;
    await render(tester, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(byId('series-summary'), findsNothing);
    expect(byId('series-cancel'), findsNothing);
    pending.completeError(
      const AppFailure('Seri jadwal tidak ditemukan atau tidak dapat diakses.'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Seri jadwal tidak ditemukan atau tidak dapat diakses.'),
      findsOneWidget,
    );
    expect(byId('series-summary'), findsNothing);
    repository.read = null;
    await tap(tester, byId('series-retry'));
    expect(byId('series-summary'), findsOneWidget);
    expect(repository.reads, ['s1', 's1']);
  });

  testWidgets(
    'cached rebuilds do not reload; pull-to-refresh loads the same series',
    (tester) async {
      viewport(tester);
      await render(tester);
      await render(tester);
      expect(repository.reads, ['s1']);
      await tester.drag(
        find.byKey(const PageStorageKey('series-detail-s1')),
        const Offset(0, 350),
      );
      await tester.pumpAndSettle();
      expect(repository.reads, ['s1', 's1']);
    },
  );

  testWidgets(
    'all meetings retains the scoped route and refreshes the series on return',
    (tester) async {
      viewport(tester);
      final routes = router(initial: '/teacher/schedule/s2');
      await render(tester, router: routes);
      await tap(tester, byId('series-sessions'));
      expect(find.text('Pertemuan s2'), findsOneWidget);
      await tap(tester, find.text('Kembali dari sesi'));
      expect(repository.reads, ['s2', 's2']);
      expect(find.text('Mingguan · 8 pertemuan'), findsOneWidget);
      await tap(tester, byId('series-back'));
      expect(find.text('Agenda guru'), findsOneWidget);
    },
  );

  testWidgets('cancel requires confirmation; dismiss leaves data untouched', (
    tester,
  ) async {
    viewport(tester);
    await render(tester);
    await tap(tester, byId('series-cancel'));
    expect(
      find.text(
        'Semua pertemuan yang masih terjadwal pada seri ini dibatalkan. Pengulangan seri ini dihentikan.',
      ),
      findsOneWidget,
    );
    expect(repository.cancelled, isEmpty);
    await tap(tester, find.text('Tidak jadi'));
    expect(repository.cancelled, isEmpty);
    expect(repository.reads, ['s1']);
    expect(
      tester.widget<FilledButton>(byId('series-cancel')).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'one cancellation request disables duplicate writes, then uses refreshed backend status',
    (tester) async {
      viewport(tester);
      await render(tester);
      final pending = Completer<void>();
      repository.cancel = (_) => pending.future;
      await confirmCancel(tester, settle: false);
      expect(repository.cancelled, ['s1']);
      expect(
        tester.widget<FilledButton>(byId('series-cancel')).onPressed,
        isNull,
      );
      expect(tester.widget<IconButton>(byId('series-back')).onPressed, isNull);
      final tile = tester.widget<ScheduleSeriesMeetingsTile>(
        byId('series-sessions'),
      );
      expect(tile.onPressed, isNull);
      await tester.pump();
      expect(repository.cancelled.length, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Dibatalkan'), findsOneWidget);
      expect(byId('series-cancel'), findsNothing);
      expect(
        find.text(
          'Seri ini sudah dibatalkan. Riwayat pertemuan tetap tersedia.',
        ),
        findsOneWidget,
      );
      expect(repository.reads, ['s1', 's1']);
      expect(
        tester
            .widget<ScheduleSeriesMeetingsTile>(byId('series-sessions'))
            .onPressed,
        isNotNull,
      );
      await dismissNotice(tester);
    },
  );

  testWidgets(
    'server rejection stays verbatim, keeps real status, and permits an explicit retry',
    (tester) async {
      viewport(tester);
      await render(tester);
      const message =
          'Seri ini tidak dapat dibatalkan. Silakan muat ulang data.';
      repository.cancel = (_) async => throw const AppFailure(message);
      await confirmCancel(tester);
      expect(find.text(message), findsOneWidget);
      expect(find.text('Terjadwal'), findsOneWidget);
      expect(repository.reads, ['s1']);
      expect(repository.cancelled, ['s1']);
      expect(
        tester.widget<FilledButton>(byId('series-cancel')).onPressed,
        isNull,
      );
      repository.cancel = null;
      await confirmCancel(tester);
      expect(repository.cancelled, ['s1', 's1']);
      expect(find.text('Dibatalkan'), findsOneWidget);
      await dismissNotice(tester);
    },
  );

  testWidgets(
    'cancelled series keeps its meeting-history link and no destructive button',
    (tester) async {
      viewport(tester);
      repository.records['s1'] = seriesFixture('s1', status: 'cancelled');
      await render(tester);
      expect(find.text('Dibatalkan'), findsOneWidget);
      expect(byId('series-cancel'), findsNothing);
      expect(byId('series-sessions'), findsOneWidget);
      expect(repository.cancelled, isEmpty);
    },
  );

  testWidgets(
    'new ID ignores the previous pending response and closing ignores late errors',
    (tester) async {
      viewport(tester);
      final old = Completer<Schedule>();
      repository.read = (id) =>
          id == 's1' ? old.future : Future.value(repository.records[id]!);
      await render(tester, settle: false);
      await render(tester, id: 's2');
      old.complete(seriesFixture('s1', status: 'cancelled'));
      await tester.pumpAndSettle();
      expect(find.text('Mingguan · 8 pertemuan'), findsOneWidget);
      expect(find.text('Terjadwal'), findsOneWidget);
      final disposed = Completer<Schedule>();
      repository.read = (_) => disposed.future;
      await render(tester, id: 's1', settle: false);
      await tester.pumpWidget(const SizedBox.shrink());
      disposed.completeError(const AppFailure('Old error'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a changed series while confirmation is open cannot cancel the new one',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tap(tester, byId('series-cancel'));
      await render(tester, id: 's2');
      await tester.enterText(
        find.byKey(const ValueKey('cancel-reason')),
        'Guru sedang sakit.',
      );
      await tap(tester, find.text('Lanjutkan'));
      await tap(tester, find.text('Ya, batalkan seri'));
      expect(repository.cancelled, isEmpty);
      expect(find.text('Mingguan · 8 pertemuan'), findsOneWidget);
    },
  );

  testWidgets(
    'late success refreshes data without showing a notice over another route',
    (tester) async {
      viewport(tester);
      final routes = router();
      await render(tester, router: routes);
      final pending = Completer<void>();
      repository.cancel = (_) => pending.future;
      await confirmCancel(tester, settle: false);
      routes.push('/other');
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Halaman lain'), findsOneWidget);
      expect(find.text('Seri dibatalkan'), findsNothing);
      expect(repository.reads, ['s1', 's1']);
      routes.pop();
      await tester.pumpAndSettle();
      expect(find.text('Dibatalkan'), findsOneWidget);
    },
  );

  testWidgets(
    '320px/large text remains scrollable with artwork below readable header',
    (tester) async {
      viewport(tester, const Size(320, 640));
      await render(tester, scale: 1.8);
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(byId('series-header-artwork')).top,
        greaterThan(
          tester
              .getRect(
                find.text(
                  'Informasi jadwal berulang untuk pertemuan dengan siswa.',
                ),
              )
              .bottom,
        ),
      );
      await tester.ensureVisible(byId('series-warning'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(byId('series-warning')).bottom,
        lessThanOrEqualTo(622),
      );
      expect(tester.takeException(), isNull);
      await tap(tester, byId('series-cancel'));
      await tap(tester, find.text('Tidak jadi'));
      expect(repository.cancelled, isEmpty);
    },
  );
}
