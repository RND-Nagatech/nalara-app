import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/app.dart';
import 'package:nalara/features/profile/presentation/pages/more_pages.dart';
import 'package:nalara/features/profile/presentation/widgets/more_menu_tile.dart';
import 'package:nalara/features/profile/presentation/widgets/more_style.dart';
import 'package:nalara/utils/app_theme.dart';

const entries = [
  (
    id: 'teaching-guide',
    title: 'Panduan mulai mengajar',
    description: 'Lanjutkan tutorial langkah demi langkah',
    route: '/teacher/getting-started',
  ),
  (
    id: 'reschedule-requests',
    title: 'Permintaan jadwal',
    description: 'Tinjau permintaan perubahan jadwal dari orang tua',
    route: '/teacher/reschedule-requests',
  ),
  (
    id: 'families',
    title: 'Orang Tua & Keluarga',
    description: 'Kelola data orang tua dan anggota keluarga siswa',
    route: '/teacher/families',
  ),
  (
    id: 'student-groups',
    title: 'Grup siswa',
    description: 'Simpan kelompok siswa untuk jadwal les rutin',
    route: '/teacher/student-groups',
  ),
  (
    id: 'materials',
    title: 'Tugas & Materi',
    description: 'Kelola tugas, materi, dan sumber belajar',
    route: '/teacher/materials',
  ),
  (
    id: 'reports',
    title: 'Laporan Belajar',
    description: 'Lihat dan kelola laporan perkembangan siswa',
    route: '/teacher/reports',
  ),
  (
    id: 'attendance',
    title: 'Presensi',
    description: 'Lihat riwayat dan kelola presensi siswa',
    route: '/teacher/attendance',
  ),
  (
    id: 'notifications',
    title: 'Notifikasi',
    description: 'Atur preferensi notifikasi',
    route: '/teacher/notifications',
  ),
  (
    id: 'subjects',
    title: 'Bidang belajar',
    description: 'Kelola bidang dan keterampilan yang diajarkan',
    route: '/teacher/subjects',
  ),
  (
    id: 'profile',
    title: 'Profil Guru',
    description: 'Lihat dan edit profil guru',
    route: '/teacher/profile',
  ),
  (
    id: 'settings',
    title: 'Pengaturan',
    description: 'Atur aplikasi sesuai kebutuhan Anda',
    route: '/teacher/settings',
  ),
  (
    id: 'help',
    title: 'Pusat Bantuan',
    description: 'Temukan jawaban atas pertanyaan Anda',
    route: '/teacher/help',
  ),
  (
    id: 'delete-account',
    title: 'Hapus akun',
    description: 'Hapus akun dan data kelolaan Anda secara permanen',
    route: '/teacher/delete-account',
  ),
];

void main() {
  void viewport(WidgetTester tester, [Size size = const Size(430, 1000)]) {
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 28, bottom: 20),
          ),
          child: child!,
        ),
        home: const MorePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'mockup header uses the supplied transparent artwork and cream safe area',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Lainnya'), findsOneWidget);
      expect(
        find.text('Kelola fitur dan pengaturan akun Anda'),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.text('Lainnya')).top,
        greaterThanOrEqualTo(28),
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        MoreStyle.cream,
      );
      final artwork = find.byKey(const ValueKey('more-header-artwork'));
      expect(
        tester.widget<Image>(artwork).image,
        isA<AssetImage>().having(
          (asset) => asset.assetName,
          'asset',
          'assets/Icon/Icon lainnya.png',
        ),
      );
      expect(tester.getSize(artwork).width, lessThanOrEqualTo(152));
      expect(tester.getCenter(artwork).dx, greaterThan(215));
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in [
    (width: 430.0, scale: 1.0, stacked: false),
    (width: 390.0, scale: 1.0, stacked: false),
    (width: 320.0, scale: 1.0, stacked: true),
    (width: 320.0, scale: 2.0, stacked: true),
    (width: 390.0, scale: 1.6, stacked: true),
  ]) {
    testWidgets(
      'header separates artwork and text at ${scenario.width}px / ${scenario.scale}x',
      (tester) async {
        viewport(tester, Size(scenario.width, 800));
        await render(tester, scale: scenario.scale);
        final intro = tester.getRect(
          find.byKey(const ValueKey('more-header-intro')),
        );
        final artwork = tester.getRect(
          find.byKey(const ValueKey('more-header-artwork')),
        );
        expect(intro.left, 22);
        expect(artwork.right, closeTo(scenario.width - 22, .01));
        expect(artwork.overlaps(intro), isFalse);
        if (scenario.stacked) {
          expect(artwork.top - intro.bottom, closeTo(12, .01));
        } else {
          expect(artwork.left - intro.right, closeTo(16, .01));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'rounded menu cards preserve their order and have space below the divider',
    (tester) async {
      viewport(tester, const Size(430, 1600));
      await render(tester);
      expect(find.byType(MoreMenuTile), findsNWidgets(entries.length));
      double previous = -1;
      for (final entry in entries) {
        final card = find.byKey(ValueKey('more-menu-${entry.id}'));
        expect(
          find.descendant(of: card, matching: find.text(entry.title)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text(entry.description)),
          findsOneWidget,
        );
        final rect = tester.getRect(card);
        expect(rect.top, greaterThan(previous));
        expect(rect.left, 18);
        expect(rect.width, 394);
        expect(rect.height, greaterThanOrEqualTo(60));
        if (entry.id == entries.first.id) {
          final divider = tester.getRect(find.byType(Divider));
          expect(rect.top, closeTo(divider.bottom + 16, .01));
        }
        previous = rect.bottom;
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('menu inset scrolls away while the viewport meets the divider', (
    tester,
  ) async {
    viewport(tester, const Size(390, 700));
    await render(tester);
    final scroll = find.byKey(const PageStorageKey('teacher-more-scroll'));
    final divider = tester.getRect(find.byType(Divider));
    final firstCard = find.byKey(ValueKey('more-menu-${entries.first.id}'));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
    );
    expect(tester.getRect(scroll).top, closeTo(divider.bottom, .01));
    expect(tester.getRect(firstCard).top, closeTo(divider.bottom + 16, .01));
    scrollable.position.jumpTo(16);
    await tester.pump();
    expect(tester.getRect(firstCard).top, closeTo(divider.bottom, .01));
    expect(tester.getRect(find.byType(Divider)), divider);
    expect(tester.getRect(scroll).top, closeTo(divider.bottom, .01));
    await tester.drag(scroll, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(Divider)), divider);
    expect(tester.getRect(scroll).top, closeTo(divider.bottom, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every entire card opens its original route and returns to the menu',
    (tester) async {
      viewport(tester);
      final router = GoRouter(
        initialLocation: '/teacher/more',
        routes: [
          GoRoute(path: '/teacher/more', builder: (_, _) => const MorePage()),
          for (final entry in entries)
            GoRoute(
              path: entry.route,
              builder: (_, _) => Scaffold(body: Text('Tujuan ${entry.id}')),
            ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      for (final entry in entries) {
        final card = find.byKey(ValueKey('more-menu-${entry.id}'));
        await tester.scrollUntilVisible(card, 200);
        await tester.pumpAndSettle();
        // Tap the trailing edge too, not just the title text.
        await tester.tap(
          find.descendant(
            of: card,
            matching: find.byIcon(Icons.chevron_right_rounded),
          ),
        );
        await tester.pumpAndSettle();
        expect(router.canPop(), isTrue);
        expect(find.text('Tujuan ${entry.id}'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(MorePage), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '320px and large text stay scrollable without clipping the final menu',
    (tester) async {
      viewport(tester, const Size(320, 568));
      await render(tester, scale: 2);
      final headerTop = tester.getTopLeft(find.text('Lainnya')).dy;
      final last = find.byKey(const ValueKey('more-menu-help'));
      await tester.scrollUntilVisible(last, 180);
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOneWidget);
      expect(tester.getTopLeft(find.text('Lainnya')).dy, headerTop);
      expect(find.text('Temukan jawaban atas pertanyaan Anda'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'existing rounded five-tab shell keeps Lainnya selected and preserves menu scroll',
    (tester) async {
      viewport(tester, const Size(390, 700));
      final router = GoRouter(
        initialLocation: '/teacher/more',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => TeacherShell(shell: shell),
            branches: [
              for (final path in ['home', 'students', 'schedule', 'targets'])
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/teacher/$path',
                      builder: (_, _) => Scaffold(body: Text('Tab $path')),
                    ),
                  ],
                ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/teacher/more',
                    builder: (_, _) => const MorePage(),
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
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      final last = find.byKey(const ValueKey('more-menu-help'));
      await tester.scrollUntilVisible(last, 160);
      await tester.pumpAndSettle();
      final top = tester.getTopLeft(last).dy;
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      expect(find.text('Tab home'), findsOneWidget);
      await tester.tap(find.text('Lainnya').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      expect(tester.getTopLeft(last).dy, closeTo(top, 1));
      expect(tester.takeException(), isNull);
    },
  );
}
