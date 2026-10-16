import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/usecases/load_progress_form.dart';
import 'package:nalara/features/learning_goals/domain/usecases/update_progress.dart';
import 'package:nalara/features/learning_goals/presentation/pages/learning_pages.dart';
import 'package:nalara/features/learning_goals/presentation/widgets/progress_form_style.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/widgets/nalara_dropdown.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'progress_form_fixtures.dart';

void main() {
  late ProgressFixtures fixture;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    fixture = ProgressFixtures();
    getIt.registerSingleton<LoadProgressForm>(fixture.load);
    getIt.registerSingleton(UpdateProgress(fixture.learning));
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
    GoRouter? router,
    bool settle = true,
    double scale = 1,
    double keyboard = 0,
  }) async {
    Widget inset(BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.only(top: 28, bottom: 18),
        textScaler: TextScaler.linear(scale),
        viewInsets: EdgeInsets.only(bottom: keyboard),
      ),
      child: child!,
    );
    await tester.pumpWidget(
      router == null
          ? MaterialApp(
              theme: buildAppTheme(),
              builder: inset,
              home: const UpdateProgressPage(id: 't1'),
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

  Future<void> setProgress(WidgetTester tester, double value) async {
    tester.widget<Slider>(byId('progress-slider')).onChanged!(value);
    await tester.pump();
  }

  Future<void> note(WidgetTester tester, String text) async {
    await tester.ensureVisible(byId('progress-note'));
    await tester.enterText(byId('progress-note'), text);
    await tester.pump();
  }

  String noteText(WidgetTester tester) =>
      tester.widget<TextFormField>(byId('progress-note')).controller!.text;
  Future<void> choose(WidgetTester tester, String field, String label) async {
    await tap(tester, byId(field));
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  GoRouter routes() {
    final router = GoRouter(
      initialLocation: '/teacher/targets/t1/update-progress',
      routes: [
        GoRoute(
          path: '/teacher/targets',
          builder: (_, _) => const Scaffold(body: Text('Daftar target')),
        ),
        GoRoute(
          path: '/teacher/targets/:targetId',
          builder: (_, _) =>
              const Scaffold(body: Text('Detail target terbaru')),
          routes: [
            GoRoute(
              path: 'update-progress',
              builder: (_, state) =>
                  UpdateProgressPage(id: state.pathParameters['targetId']!),
            ),
          ],
        ),
        GoRoute(
          path: '/other',
          builder: (_, _) => const Scaffold(body: Text('Halaman lain')),
        ),
      ],
    );
    addTearDown(router.dispose);
    return router;
  }

  testWidgets(
    'mockup layout uses real identity/period, initials, slider, five presets and shared sessions',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Update Progress'), findsOneWidget);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        ProgressFormStyle.cream,
      );
      expect(
        tester.getRect(byId('progress-back')).top,
        greaterThanOrEqualTo(28),
      );
      expect(find.text('Alya'), findsOneWidget);
      expect(find.text('Kelas 5 · Matematika'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Andi'), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Operasi pecahan'), findsOneWidget);
      expect(
        find.text('Periode target · 12 Okt 2026 – 18 Okt 2026'),
        findsOneWidget,
      );
      expect(tester.widget<Text>(byId('progress-value')).data, '20%');
      for (final preset in [0, 25, 50, 75, 100]) {
        expect(byId('progress-preset-$preset'), findsOneWidget);
      }
      final slider = tester.widget<Slider>(byId('progress-slider'));
      expect(slider.min, 0);
      expect(slider.max, 100);
      expect(slider.divisions, 100);
      final session = tester.widget<NalaraDropdown<String>>(
        byId('progress-session'),
      );
      expect(session.value, '');
      expect(session.options.map((option) => option.value), ['', 'l1', 'l2']);
      expect(session.options[1].label, '16 Okt 2026 · 10:00 – 11:00');
      expect(find.text('Visibilitas: Hanya Guru'), findsOneWidget);
      expect(byId('progress-visibility'), findsNothing);
      expect(fixture.learning.writes, isEmpty);
    },
  );

  testWidgets(
    'presets and slider round to integers; backend rejection retains all draft fields',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tap(tester, byId('progress-preset-75'));
      expect(tester.widget<Slider>(byId('progress-slider')).value, 75);
      await setProgress(tester, 60.2);
      expect(tester.widget<Text>(byId('progress-value')).data, '60%');
      await note(tester, 'Semakin mandiri');
      await choose(tester, 'progress-session', '16 Okt 2026 · 10:00 – 11:00');
      await tap(tester, byId('progress-settings'));
      await choose(tester, 'progress-visibility', 'Untuk siswa / Orang Tua');
      const message = 'Target berubah. Muat ulang sebelum menyimpan.';
      fixture.learning.update = (_) async => throw const AppFailure(message);
      await tap(tester, byId('progress-save'));
      expect(find.text(message), findsOneWidget);
      final write = fixture.learning.writes.single;
      expect(write.id, 't1');
      expect(write.update.progress, 60);
      expect(write.update.version, 5);
      expect(write.update.note, 'Semakin mandiri');
      expect(write.update.sessionId, 'l1');
      expect(write.update.visibility, 'shared');
      expect(noteText(tester), 'Semakin mandiri');
      expect(tester.widget<Slider>(byId('progress-slider')).value, 60);
    },
  );

  testWidgets(
    'save uses a single versioned request, disables controls and returns through existing navigation',
    (tester) async {
      viewport(tester);
      final router = routes();
      await render(tester, router: router);
      final pending = Completer<LearningTarget>();
      fixture.learning.update = (_) => pending.future;
      await setProgress(tester, 60);
      await tap(tester, byId('progress-save'), settle: false);
      expect(
        tester.widget<FilledButton>(byId('progress-save')).onPressed,
        isNull,
      );
      expect(tester.widget<Slider>(byId('progress-slider')).onChanged, isNull);
      expect(
        tester.widget<TextButton>(byId('progress-preset-100')).onPressed,
        isNull,
      );
      expect(fixture.learning.writes.length, 1);
      expect(fixture.learning.writes.single.update.sessionId, isNull);
      expect(fixture.learning.writes.single.update.visibility, 'teacher');
      pending.complete(progressTarget(progress: 60, version: 6));
      await tester.pumpAndSettle();
      expect(find.text('Detail target terbaru'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'explicit reload confirms replacing draft progress, preserving notes and using the new server version',
    (tester) async {
      viewport(tester);
      await render(tester);
      await setProgress(tester, 60);
      await note(tester, 'Jangan hilang');
      fixture.learning.update = (_) async => throw const AppFailure(
        'Target berubah. Muat ulang sebelum menyimpan.',
      );
      await tap(tester, byId('progress-save'));
      fixture.learning.current = progressTarget(progress: 40, version: 6);
      await tap(tester, byId('progress-reload-error'));
      await tap(tester, find.text('Batal'));
      expect(tester.widget<Slider>(byId('progress-slider')).value, 60);
      expect(fixture.learning.reads.length, 1);
      await tap(tester, byId('progress-reload-error'));
      await tap(tester, find.text('Lanjutkan'));
      expect(tester.widget<Slider>(byId('progress-slider')).value, 40);
      expect(noteText(tester), 'Jangan hilang');
      await tap(tester, byId('progress-preset-75'));
      await tap(tester, byId('progress-save'));
      expect(fixture.learning.writes.last.update.version, 6);
      expect(fixture.learning.writes.last.update.progress, 75);
      expect(fixture.learning.writes.last.update.note, 'Jangan hilang');
    },
  );

  testWidgets(
    'loading/error/retry and cached rebuilds never fabricate a student or repeat successful loading',
    (tester) async {
      viewport(tester);
      final pending = Completer<LearningTarget>();
      fixture.learning.read = () => pending.future;
      await render(tester, settle: false);
      expect(byId('progress-slider'), findsNothing);
      pending.completeError(const AppFailure('Target tidak dapat diakses'));
      await tester.pumpAndSettle();
      expect(find.text('Target tidak dapat diakses'), findsOneWidget);
      expect(find.text('Alya'), findsNothing);
      fixture.learning.read = null;
      await tap(tester, find.text('Coba lagi'));
      expect(byId('progress-slider'), findsOneWidget);
      final reads = fixture.learning.reads.length;
      await render(tester);
      expect(fixture.learning.reads.length, reads);
    },
  );

  testWidgets(
    '320px large-text keyboard layout scrolls to the save action without overflow',
    (tester) async {
      viewport(tester, const Size(320, 700));
      await render(tester, scale: 1.7, keyboard: 180);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(byId('progress-save'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(byId('progress-save')).bottom,
        lessThanOrEqualTo(520),
      );
      expect(tester.takeException(), isNull);
      final field = tester.widget<TextField>(
        find.descendant(
          of: byId('progress-note'),
          matching: find.byType(TextField),
        ),
      );
      expect(field.maxLength, 3000);
    },
  );

  testWidgets(
    'late completion after dispose or navigation never pops another route or displays success over it',
    (tester) async {
      viewport(tester);
      final router = routes();
      await render(tester, router: router);
      final pending = Completer<LearningTarget>();
      fixture.learning.update = (_) => pending.future;
      await tap(tester, byId('progress-save'), settle: false);
      router.push('/other');
      await tester.pump();
      pending.complete(progressTarget());
      await tester.pumpAndSettle();
      expect(find.text('Halaman lain'), findsOneWidget);
      expect(find.text('Progress dan riwayat disimpan'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
