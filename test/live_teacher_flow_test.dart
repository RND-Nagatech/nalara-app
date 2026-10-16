import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/app.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/learning_goals/domain/repositories/learning_repository.dart';
import 'package:nalara/features/students/domain/repositories/students_repository.dart';
import 'package:nalara/utils/constants.dart';
import 'package:nalara/utils/injector.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    if (finder.evaluate().isNotEmpty) return;
  }
  final labels = find
      .byType(Text)
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .take(50)
      .join(' | ');
  fail(
    'Timed out waiting for $finder. UI: $labels. Exception: ${tester.takeException()}',
  );
}

Future<void> click(WidgetTester tester, Finder finder) async {
  await waitFor(tester, finder);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 500));
}

Finder field(String label) => find.widgetWithText(TextFormField, label);
Future<void> scrollFor(WidgetTester tester, Finder finder) async {
  final scrollable = find
      .descendant(
        of: find.byType(ListView).last,
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(finder, 300, scrollable: scrollable);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real API: login → student → multiple targets → progress 20 to 60 → history',
    (tester) async {
      HttpOverrides.global = null;
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterSecureStorage.setMockInitialValues({});
      tz.initializeTimeZones();
      await initializeDateFormatting('id_ID');
      await getIt.reset();
      await configureDependencies(checkInstallation: false);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final email = 'ui-$stamp@nalara.example.test';
      final phone = '081${(stamp % 1000000000).toString().padLeft(9, '0')}';
      const password = 'LocalUiTestPassword123!';
      await tester.runAsync(() async {
        await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
          ApiConstants.register,
          data: {
            'name': 'Guru UI Test',
            'email': email,
            'phone': phone,
            'password': password,
            'passwordConfirmation': password,
          },
        );
        await getIt<AuthRepository>().completeOnboarding();
        await getIt<AuthCubit>().restore();
      });
      await tester.pumpWidget(const NalaraApp());
      await waitFor(tester, find.byKey(const ValueKey('role-teacher')));
      await click(tester, find.byKey(const ValueKey('role-teacher')));
      await waitFor(tester, find.byKey(const ValueKey('auth-login-header')));
      await tester.enterText(find.byKey(const ValueKey('auth-email')), email);
      await tester.enterText(
        find.byKey(const ValueKey('auth-password')),
        password,
      );
      await click(tester, find.widgetWithText(FilledButton, 'Masuk'));
      await waitFor(tester, find.text('GURU UI TEST 👋'));
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await click(tester, find.text('Siswa').last);
      await click(tester, find.byKey(const ValueKey('students-add-empty')));
      await waitFor(tester, find.byKey(const ValueKey('student-name')));
      await tester.enterText(
        find.byKey(const ValueKey('student-name')),
        'Alya UI $stamp',
      );
      await tester.enterText(
        find.byKey(const ValueKey('student-grade')),
        'Kelas 5',
      );
      await click(tester, find.widgetWithText(FilledButton, 'Tambah siswa'));
      await waitFor(tester, find.text('Alya UI $stamp'));
      await click(tester, find.text('Lainnya'));
      await click(tester, find.text('Bidang belajar'));
      await click(tester, find.byKey(const ValueKey('subjects-add')));
      await waitFor(tester, find.byKey(const ValueKey('subject-name')));
      await tester.enterText(
        find.byKey(const ValueKey('subject-name')),
        'Matematika',
      );
      await click(tester, find.widgetWithText(FilledButton, 'Simpan'));
      await waitFor(tester, find.text('Matematika'));
      await click(tester, find.text('Target'));
      await click(tester, find.byKey(const ValueKey('target-add-empty')));
      final firstTarget = find.byKey(const ValueKey('plan-target-title-0'));
      final secondTarget = find.byKey(const ValueKey('plan-target-title-1'));
      await waitFor(tester, firstTarget);
      await tester.ensureVisible(firstTarget);
      await tester.enterText(firstTarget, 'Memahami pecahan');
      await scrollFor(tester, find.text('Tambah target lagi'));
      await click(tester, find.text('Tambah target lagi'));
      await tester.pump();
      await scrollFor(tester, find.text('Target 2'));
      await tester.ensureVisible(secondTarget);
      await tester.enterText(secondTarget, 'Operasi pecahan');
      await scrollFor(tester, find.text('Simpan rencana & target'));
      await click(tester, find.text('Simpan rencana & target'));
      await waitFor(tester, find.text('Rencana belajar mingguan'));
      await click(tester, find.text('Rencana belajar mingguan'));
      await click(tester, find.text('Memahami pecahan'));
      await click(tester, find.text('Update progress'));
      final progressSlider = find.byKey(const ValueKey('progress-slider'));
      await waitFor(tester, progressSlider);
      tester.widget<Slider>(progressSlider).onChanged!(20);
      await tester.pump();
      await click(tester, find.byKey(const ValueKey('progress-save')));
      await waitFor(tester, find.text('Progress target'));
      await waitFor(tester, find.text('20%'));
      await click(tester, find.text('Update progress'));
      await waitFor(tester, progressSlider);
      tester.widget<Slider>(progressSlider).onChanged!(60);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('progress-note')),
        'Semakin mandiri',
      );
      await click(tester, find.byKey(const ValueKey('progress-save')));
      await waitFor(tester, find.text('60%'));
      await click(tester, find.text('Riwayat perkembangan'));
      await waitFor(tester, find.text('20% → 60%'));
      expect(find.text('Semakin mandiri'), findsOneWidget);
      await tester.runAsync(() async {
        final students = await getIt<StudentsRepository>().list();
        expect(students.items.single.name, 'Alya UI $stamp');
        final plans = await getIt<LearningRepository>().plans();
        expect(plans.items.single.progress, 30);
        final detail = await getIt<LearningRepository>().plan(
          plans.items.single.id,
        );
        expect(detail.targets.length, 2);
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      getIt<Dio>().close(force: true);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(seconds: 4));
      await getIt.reset();
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_TESTS'),
  );
}
