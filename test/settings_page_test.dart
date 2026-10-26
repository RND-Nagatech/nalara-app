import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/profile/presentation/pages/more_pages.dart';
import 'package:nalara/features/profile/presentation/widgets/settings_style.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/profile/domain/teacher_profile_repository.dart';
import 'package:nalara/shared/widgets/nalara_dropdown.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/injector.dart';

class _SettingsAuth extends Fake implements AuthRepository {
  @override
  Future<Teacher> login(
    String identifier,
    String password, {
    bool rememberMe = true,
    LoginMethod method = LoginMethod.email,
  }) async => const Teacher(
    id: 'teacher',
    name: 'Guru',
    email: 'guru@example.test',
    workspaceId: 'workspace',
    timezone: 'Asia/Jakarta',
  );
  @override
  Future<void> completeOnboarding() async {}
}

class _SettingsProfile implements TeacherProfileRepository {
  int saves = 0;
  Completer<String>? pending;
  Object? error;
  @override
  Future<String> updatePhone(String phone) async => phone;
  @override
  Future<String> updateTimezone(String timezone) async {
    saves++;
    if (error != null) throw error!;
    return pending?.future ?? timezone;
  }
}

void main() {
  late _SettingsProfile profile;
  setUp(() async {
    final auth = AuthCubit(_SettingsAuth());
    getIt.registerSingleton<AuthCubit>(auth, dispose: (cubit) => cubit.close());
    profile = _SettingsProfile();
    getIt.registerFactory<TeacherProfileRepository>(() => profile);
    await auth.login('guru@example.test', 'password');
  });
  tearDown(() => getIt.reset());
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
    'language/privacy stay read-only and timezone uses the shared selector with an explicit save',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      expect(find.text('WIB · Jakarta (UTC+7)'), findsOneWidget);
      expect(
        find.text(
          'Catatan internal hanya untuk Guru. Pilih visibilitas saat menyimpan progress atau laporan.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SettingsInfoRow), findsOneWidget);
      expect(find.byType(NalaraDropdown<String>), findsOneWidget);
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
      expect(
        tester.widget<FilledButton>(key('timezone-save')).onPressed,
        isNull,
      );
      expect(find.textContaining('24/7'), findsNothing);
    },
  );

  testWidgets(
    'confirmed timezone save updates the account, not just the selected label',
    (tester) async {
      viewport(tester);
      await render(tester);
      tester.widget<NalaraDropdown<String>>(key('timezone')).onChanged!(
        'Asia/Makassar',
      );
      await tester.pump();
      expect(getIt<AuthCubit>().state.teacher!.timezone, 'Asia/Jakarta');
      await tap(tester, key('timezone-save'));
      expect(getIt<AuthCubit>().state.teacher!.timezone, 'Asia/Makassar');
      expect(find.text('WITA · Makassar (UTC+8)'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(key('timezone-save')).onPressed,
        isNull,
      );
      expect(find.text('Zona waktu berhasil disimpan.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'save shows an in-button spinner, locks actions and notifies only after confirmation',
    (tester) async {
      viewport(tester);
      profile.pending = Completer<String>();
      await render(tester);
      tester.widget<NalaraDropdown<String>>(key('timezone')).onChanged!(
        'Asia/Jayapura',
      );
      await tester.pump();
      await tester.ensureVisible(key('timezone-save'));
      await tester.tap(key('timezone-save'));
      await tester.pump();
      expect(
        find.descendant(
          of: key('timezone-save'),
          matching: key('timezone-saving'),
        ),
        findsOneWidget,
      );
      expect(find.text('Menyimpan…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(key('timezone-save')).onPressed,
        isNull,
      );
      expect(
        tester.widget<NalaraDropdown<String>>(key('timezone')).enabled,
        isFalse,
      );
      expect(find.text('Zona waktu berhasil disimpan.'), findsNothing);
      expect(getIt<AuthCubit>().state.teacher!.timezone, 'Asia/Jakarta');
      expect(profile.saves, 1);
      profile.pending!.complete('Asia/Jayapura');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(key('timezone-saving'), findsNothing);
      expect(find.text('Zona waktu berhasil disimpan.'), findsOneWidget);
      expect(getIt<AuthCubit>().state.teacher!.timezone, 'Asia/Jayapura');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Zona waktu berhasil disimpan.'), findsNothing);
    },
  );

  testWidgets('failed save keeps the draft and shows no success notification', (
    tester,
  ) async {
    viewport(tester);
    profile.error = const AppFailure('Server tidak terhubung');
    await render(tester);
    tester.widget<NalaraDropdown<String>>(key('timezone')).onChanged!(
      'Asia/Makassar',
    );
    await tester.pump();
    await tap(tester, key('timezone-save'));
    expect(key('timezone-saving'), findsNothing);
    expect(find.text('Zona waktu berhasil disimpan.'), findsNothing);
    expect(find.text('Server tidak terhubung'), findsOneWidget);
    expect(
      tester.widget<NalaraDropdown<String>>(key('timezone')).value,
      'Asia/Makassar',
    );
    expect(
      tester.widget<FilledButton>(key('timezone-save')).onPressed,
      isNotNull,
    );
    expect(getIt<AuthCubit>().state.teacher!.timezone, 'Asia/Jakarta');
  });

  testWidgets(
    'closing the editor suppresses a delayed success notice without losing the confirmed account update',
    (tester) async {
      viewport(tester);
      profile.pending = Completer<String>();
      await render(tester);
      tester.widget<NalaraDropdown<String>>(key('timezone')).onChanged!(
        'Asia/Makassar',
      );
      await tester.pump();
      await tester.ensureVisible(key('timezone-save'));
      await tester.tap(key('timezone-save'));
      await tester.pump();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Halaman lain'))),
      );
      profile.pending!.complete('Asia/Makassar');
      await tester.pumpAndSettle();
      expect(find.text('Zona waktu berhasil disimpan.'), findsNothing);
      expect(getIt<AuthCubit>().state.teacher!.timezone, 'Asia/Makassar');
      expect(tester.takeException(), isNull);
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
