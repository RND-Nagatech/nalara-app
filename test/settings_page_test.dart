import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/profile/presentation/pages/more_pages.dart';
import 'package:nalara/features/profile/presentation/widgets/settings_style.dart';
import 'package:nalara/utils/app_theme.dart';

void main() {
  Finder key(String id) => find.byKey(ValueKey('settings-$id'));

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
        home: const SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cream SafeArea and original artwork replace the generic app bar',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(tester.getRect(key('back')).top, greaterThanOrEqualTo(28));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        SettingsStyle.cream,
      );
      expect(
        tester.widget<Image>(key('artwork')).image,
        isA<AssetImage>().having(
          (asset) => asset.assetName,
          'asset',
          'assets/Icon/Icon lainnya.png',
        ),
      );
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'existing language, default time and privacy remain read-only without fake controls',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      expect(find.text('WIB · Asia/Jakarta'), findsOneWidget);
      expect(
        find.text(
          'Catatan internal hanya untuk Guru. Pilih visibilitas saat menyimpan progress atau laporan.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SettingsInfoRow), findsNWidgets(2));
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(
        tester.getRect(key('preferences')).top,
        lessThan(tester.getRect(key('privacy')).top),
      );
      expect(
        tester.getRect(key('privacy')).top,
        lessThan(tester.getRect(key('help')).top),
      );
      expect(find.textContaining('Simpan'), findsNothing);
      expect(find.textContaining('24/7'), findsNothing);
    },
  );

  testWidgets(
    'existing legal/help routes return to settings and back supports stack or fallback',
    (tester) async {
      viewport(tester);
      final destinations = {
        'open-privacy': '/legal/kebijakan-privasi',
        'open-terms': '/legal/syarat-dan-ketentuan',
        'open-help': '/teacher/help',
      };
      final router = GoRouter(
        initialLocation: '/teacher/settings',
        routes: [
          GoRoute(
            path: '/teacher/settings',
            builder: (_, _) => const SettingsPage(),
          ),
          GoRoute(
            path: '/teacher/more',
            builder: (_, _) => const Scaffold(body: Text('Menu Lainnya')),
          ),
          for (final route in destinations.values)
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
      for (final entry in destinations.entries) {
        await tap(tester, key(entry.key));
        expect(find.text('Tujuan ${entry.value}'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('Pengaturan'), findsOneWidget);
      }
      await tap(tester, key('back'));
      expect(find.text('Menu Lainnya'), findsOneWidget);
      router.push('/teacher/settings');
      await tester.pumpAndSettle();
      await tap(tester, key('back'));
      expect(find.text('Menu Lainnya'), findsOneWidget);
    },
  );

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets('settings remain scrollable at $size and large text', (
      tester,
    ) async {
      viewport(tester, size);
      await render(tester, scale: 1.8);
      await tester.ensureVisible(key('open-help'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(key('open-help')).bottom,
        lessThanOrEqualTo(size.height - 20),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
