import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/notifications/domain/entities/notification.dart';
import 'package:nalara/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nalara/features/notifications/presentation/pages/notifications_page.dart';
import 'package:nalara/features/notifications/presentation/widgets/notification_card.dart';
import 'package:nalara/features/notifications/presentation/widgets/notifications_style.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'notifications_fixtures.dart';

void main() {
  late NotificationsFake repository;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    repository = NotificationsFake();
    getIt.registerSingleton<NotificationsRepository>(repository);
  });
  tearDown(() => getIt.reset());
  Finder key(String id) => find.byKey(ValueKey('notifications-$id'));
  Finder read(String id) => find.byKey(ValueKey('notification-read-$id'));
  Finder open(String id) => find.byKey(ValueKey('notification-open-$id'));
  void viewport(WidgetTester tester, [Size size = const Size(430, 1000)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(
    WidgetTester tester, {
    double scale = 1,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 28, bottom: 20),
          ),
          child: child!,
        ),
        home: const NotificationsPage(),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<GoRouter> routed(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/teacher/notifications',
      routes: [
        GoRoute(
          path: '/teacher/notifications',
          builder: (_, _) => const NotificationsPage(),
        ),
        for (final route in [
          '/teacher/reports/report-1',
          '/teacher/more',
          '/teacher/elsewhere',
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

  testWidgets(
    'successful empty uses the existing document artwork, max 240, cream SafeArea',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Belum ada notifikasi'), findsOneWidget);
      expect(tester.getRect(key('back')).top, greaterThanOrEqualTo(28));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        NotificationsStyle.cream,
      );
      expect(
        tester.widget<Image>(key('empty-artwork')).image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'asset',
          'assets/Icon/Icon laporan belum selesai.png',
        ),
      );
      expect(
        tester.getSize(key('empty-artwork')).width,
        lessThanOrEqualTo(240),
      );
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(NotificationCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading and API failure never show the empty illustration; retry works',
    (tester) async {
      viewport(tester);
      final response = Completer<PageResult<TeacherNotification>>();
      repository.respond = (_) => response.future;
      await render(tester, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(key('empty-artwork'), findsNothing);
      response.completeError(const AppFailure('Akses notifikasi ditolak'));
      await tester.pumpAndSettle();
      expect(find.text('Akses notifikasi ditolak'), findsOneWidget);
      expect(key('empty-artwork'), findsNothing);
      repository.respond = null;
      await tap(tester, key('retry'));
      expect(key('empty-artwork'), findsOneWidget);
    },
  );

  testWidgets(
    'real content and read status use compact cards; save only spins on its item',
    (tester) async {
      viewport(tester);
      repository.records = [
        notificationFixture('one'),
        notificationFixture('two'),
        notificationFixture('old', read: true),
      ];
      await render(tester);
      expect(find.text('3 notifikasi'), findsOneWidget);
      expect(find.text('15 Okt 2026 · 15:18 WIB'), findsNWidgets(3));
      expect(find.text('Baru'), findsNWidgets(2));
      expect(read('old'), findsNothing);
      repository.readGate = Completer<void>();
      await tester.tap(read('one'));
      await tester.pump();
      expect(
        find.descendant(
          of: read('one'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: read('two'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
      expect(tester.widget<TextButton>(read('two')).onPressed, isNull);
      repository.readGate!.complete();
      await tester.pumpAndSettle();
      expect(read('one'), findsNothing);
      expect(repository.reads, ['one']);
      expect(repository.pages, [1, 1]);
    },
  );

  testWidgets(
    'raw write error stays on the failed card and does not mark it read',
    (tester) async {
      viewport(tester);
      repository.records = [notificationFixture('one')];
      repository.readError = const AppFailure('Tidak dapat menandai dibaca');
      await render(tester);
      await tap(tester, read('one'));
      expect(find.text('Tidak dapat menandai dibaca'), findsOneWidget);
      expect(find.text('Baru'), findsOneWidget);
      expect(repository.records.single.read, isFalse);
    },
  );

  testWidgets('load more appends data and refresh resets to the first batch', (
    tester,
  ) async {
    viewport(tester);
    repository.records = [
      notificationFixture('one'),
      notificationFixture('two'),
    ];
    repository.limit = 1;
    await render(tester);
    await tap(tester, key('load-more'));
    expect(find.text('Laporan two'), findsOneWidget);
    await tap(tester, key('refresh'));
    expect(repository.pages, [1, 2, 1]);
    expect(find.text('Laporan one'), findsOneWidget);
  });

  testWidgets(
    'opening marks read before teacher navigation and refreshes after return',
    (tester) async {
      viewport(tester);
      repository.records = [notificationFixture('one')];
      final router = await routed(tester);
      await tap(tester, open('one'));
      expect(repository.reads, ['one']);
      expect(find.text('Tujuan /teacher/reports/report-1'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Dibaca'), findsOneWidget);
      await tap(tester, open('one'));
      expect(repository.reads, ['one']);
      router.pop();
      await tester.pumpAndSettle();
      await tap(tester, key('back'));
      expect(find.text('Tujuan /teacher/more'), findsOneWidget);
    },
  );

  testWidgets('late read completion cannot navigate over another route', (
    tester,
  ) async {
    viewport(tester);
    repository.records = [notificationFixture('one')];
    repository.readGate = Completer<void>();
    final router = await routed(tester);
    await tester.tap(open('one'));
    await tester.pump();
    router.push('/teacher/elsewhere');
    await tester.pumpAndSettle();
    repository.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Tujuan /teacher/elsewhere'), findsOneWidget);
    expect(find.text('Tujuan /teacher/reports/report-1'), findsNothing);
  });

  testWidgets('non-teacher destinations are not opened', (tester) async {
    viewport(tester);
    repository.records = [
      notificationFixture('one', route: 'https://example.invalid'),
    ];
    await routed(tester);
    await tap(tester, open('one'));
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(repository.reads, ['one']);
    expect(find.text('Dibaca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an empty page with a nonzero total is not the global empty state',
    (tester) async {
      viewport(tester);
      repository.respond = (_) async =>
          const PageResult(items: [], total: 30, page: 2, limit: 20);
      await render(tester);
      expect(key('empty-artwork'), findsNothing);
      expect(find.text('30 notifikasi'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('notifications-load-more')),
        findsNothing,
      );
      expect(find.textContaining('Coba halaman sebelumnya'), findsNothing);
    },
  );

  for (final empty in [true, false]) {
    testWidgets('empty=$empty remains scrollable at 320px and large text', (
      tester,
    ) async {
      viewport(tester, const Size(320, 640));
      if (!empty) {
        repository.records = [
          notificationFixture(
            'long',
            title:
                'Judul notifikasi panjang untuk aktivitas belajar dan laporan siswa',
            body: 'Catatan perkembangan siswa dengan isi yang panjang. ' * 10,
          ),
        ];
      }
      await render(tester, scale: 1.8);
      if (!empty) await tester.scrollUntilVisible(read('long'), 200);
      expect(tester.takeException(), isNull);
    });
  }
}
