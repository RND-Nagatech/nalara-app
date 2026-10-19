import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/profile/presentation/pages/help_page.dart';
import 'package:nalara/features/teaching_guide/presentation/session_teaching_guide.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_guide_card.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_guide_cubit.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_guide_page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'teaching_guide_fixtures.dart';

void main() {
  late TeachingGuideFake repository;
  late TeachingGuideCubit cubit;

  setUp(() {
    repository = TeachingGuideFake(guideValue());
    cubit = TeachingGuideCubit(repository);
  });
  tearDown(() async {
    await cubit.close();
    await getIt.reset();
  });

  Finder key(String name) => find.byKey(ValueKey('teaching-guide-$name'));
  Future<void> card(
    WidgetTester tester, {
    bool inHome = true,
    double scale = 1,
    ValueChanged<String>? onOpen,
    VoidCallback? onOpenGuide,
  }) async {
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: TeachingGuideCard(
              cubit: cubit,
              inHome: inHome,
              onOpen: onOpen ?? (_) {},
              onOpenGuide: onOpenGuide ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'next action is based on saved data, opening a form does not complete it',
    (tester) async {
      repository.value = guideValue(subject: true, student: true);
      final routes = <String>[];
      await card(tester, onOpen: routes.add);
      expect(find.text('2 dari 4 langkah selesai'), findsOneWidget);
      await tester.ensureVisible(key('next'));
      await tester.tap(key('next'));
      await tester.pumpAndSettle();
      expect(routes, ['/teacher/schedule/new']);
      expect(cubit.state.value!.completedCount, 2);
      expect(repository.saves, isEmpty);
    },
  );

  testWidgets(
    'skip collapses the guide, keeps progress and offers an explicit reopen',
    (tester) async {
      var opened = false;
      repository.value = guideValue(subject: true);
      await card(tester, onOpenGuide: () => opened = true);
      await tester.ensureVisible(key('dismiss'));
      await tester.tap(key('dismiss'));
      await tester.pumpAndSettle();
      expect(repository.saves, [true]);
      expect(find.text('1 dari 4 langkah selesai'), findsOneWidget);
      expect(key('next'), findsNothing);
      await tester.ensureVisible(key('open'));
      await tester.tap(key('open'));
      expect(opened, isTrue);
    },
  );

  testWidgets('completed setup is compact without requiring parent access', (
    tester,
  ) async {
    repository.value = guideValue(
      subject: true,
      student: true,
      schedule: true,
      target: true,
    );
    await card(tester);
    expect(find.text('Persiapan mengajar selesai'), findsOneWidget);
    expect(key('open'), findsOneWidget);
    expect(key('next'), findsNothing);
    expect(key('families'), findsNothing);
  });

  testWidgets(
    'backend error never fabricates progress or successful dismissal',
    (tester) async {
      repository.loadError = const AppFailure('Panduan belum tersedia.');
      await card(tester);
      expect(find.text('Panduan belum tersedia.'), findsOneWidget);
      expect(key('progress'), findsNothing);
      repository.loadError = null;
      await tester.tap(key('retry'));
      await tester.pumpAndSettle();
      repository.saveError = const AppFailure('Pilihan gagal disimpan.');
      await tester.ensureVisible(key('dismiss'));
      await tester.tap(key('dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Pilihan gagal disimpan.'), findsOneWidget);
      expect(key('next'), findsOneWidget);
    },
  );

  testWidgets(
    'full page reloads from backend after cancel/save and supports direct back entry',
    (tester) async {
      getIt.registerFactory(() => TeachingGuideCubit(repository));
      final router = GoRouter(
        initialLocation: '/teacher/getting-started',
        routes: [
          GoRoute(
            path: '/teacher/getting-started',
            builder: (_, _) => const TeachingGuidePage(),
          ),
          GoRoute(
            path: '/teacher/subjects/new',
            builder: (context, _) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      repository.value = guideValue(subject: true);
                      context.pop();
                    },
                    child: const Text('Simpan bidang'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/teacher/home',
            builder: (_, _) => const Scaffold(body: Text('Beranda')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      for (final action in ['Batal', 'Simpan bidang']) {
        await tester.ensureVisible(key('next'));
        await tester.tap(key('next'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        expect(
          find.text('${action == 'Batal' ? 0 : 1} dari 4 langkah selesai'),
          findsOneWidget,
        );
      }
      expect(repository.reads, 3);
      expect(key('families'), findsOneWidget);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/teacher/home');
    },
  );

  testWidgets(
    'full checklist and actions remain scrollable at 320px with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await card(tester, inHome: false, scale: 2);
      await tester.ensureVisible(key('next'));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(key('families'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('parent/student Help never offers teacher setup actions', (
    tester,
  ) async {
    for (final role in ['parent', 'student']) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HelpPage(routePrefix: '/$role'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('help-open-teaching-guide')),
        findsNothing,
      );
    }
  });

  testWidgets(
    'session guidance follows attendance/report state without writing anything',
    (tester) async {
      Future<void> render(bool attendance, bool report) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTeachingGuide(
                attendanceRecorded: attendance,
                reportPublished: report,
              ),
            ),
          ),
        );
      }

      await render(false, false);
      expect(
        find.textContaining('Setelah pertemuan berlangsung'),
        findsOneWidget,
      );
      await render(true, false);
      expect(find.textContaining('Presensi sudah dicatat'), findsOneWidget);
      await render(true, true);
      expect(find.text('Panduan sesi'), findsNothing);
    },
  );
}
