import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/teaching_guide/domain/teaching_guide.dart';
import 'package:nalara/features/teaching_guide/presentation/session_teaching_guide.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_guide_card.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_guide_cubit.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_tutorial_host.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_tutorial_scope.dart';
import 'package:nalara/features/teaching_guide/presentation/tutorial_completion_sheet.dart';
import 'package:nalara/shared/widgets/nalara_celebration_sheet.dart';
import 'package:nalara/utils/app_theme.dart';
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
  });

  Future<GoRouter> renderTour(
    WidgetTester tester, {
    bool finalTarget = false,
  }) async {
    final resource = finalTarget ? 'targets' : 'students';
    final anchor = finalTarget ? 'target' : 'student';
    final root = '/teacher/$resource';
    final router = GoRouter(
      initialLocation: '/teacher/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(body: shell),
          branches: [
            for (final path in ['/teacher/home', root, '/teacher/more'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, _) => Scaffold(
                      body: Column(
                        children: [
                          Text(path),
                          if (path == '/teacher/home')
                            TutorialTarget(
                              id: 'menu-$anchor',
                              child: TextButton(
                                onPressed: () => context.go(root),
                                child: Text(finalTarget ? 'Target' : 'Siswa'),
                              ),
                            ),
                          if (path == root)
                            TutorialTarget(
                              id: 'add-$anchor',
                              child: TextButton(
                                onPressed: () => context.push('$root/new'),
                                child: Text(
                                  finalTarget
                                      ? 'Tambah target'
                                      : 'Tambah siswa',
                                ),
                              ),
                            ),
                          const RemainingGuideBadge(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        GoRoute(
          path: '$root/new',
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                TutorialTarget(id: 'form-$anchor', child: const TextField()),
                TutorialTarget(
                  id: 'save-$anchor',
                  child: TextButton(
                    onPressed: () async {
                      repository.value = guideValue(
                        tutorialSeen: true,
                        subject: true,
                        student: true,
                        schedule: finalTarget,
                        target: finalTarget,
                      );
                      await cubit.load();
                      if (context.mounted) context.pop();
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: router,
        builder: (_, child) => TeachingTutorialHost(
          guide: cubit,
          router: router,
          teacherId: 'teacher-a',
          enabled: true,
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'automatic first-use tour can be skipped without completing work',
    (tester) async {
      repository.value = guideValue(subject: true);
      final router = await renderTour(tester);
      expect(find.text('1/5'), findsOneWidget);
      expect(repository.saves, [true]);
      expect(cubit.state.value!.remainingCount, 3);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsNothing);
      expect(cubit.state.value!.remainingCount, 3);
      router.go('/teacher/more');
      await tester.pumpAndSettle();
      router.go('/teacher/home');
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsNothing);
    },
  );

  testWidgets('opening and cancelling a form never completes the tutorial', (
    tester,
  ) async {
    repository.value = guideValue(subject: true);
    final router = await renderTour(tester);
    await tester.tap(find.byKey(const ValueKey('tutorial-next')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/teacher/students');
    await tester.tap(find.byKey(const ValueKey('tutorial-next')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/teacher/students/new');
    expect(find.text('3/5'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(cubit.state.value!.hasStudent, isFalse);
    expect(find.text('2/5'), findsOneWidget);
  });

  testWidgets(
    'only a confirmed save finishes a tutorial and lowers the badge',
    (tester) async {
      repository.value = guideValue(subject: true);
      await renderTour(tester);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('tutorial-next')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Tunjukkan tombol simpan'));
      await tester.pumpAndSettle();
      expect(find.text('4/5'), findsOneWidget);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('5/5'), findsOneWidget);
      expect(cubit.state.value!.remainingCount, 2);
      expect(find.byType(TutorialCompletionSheet), findsNothing);
    },
  );

  testWidgets('completed tutors get no automatic tutorial', (tester) async {
    repository.value = guideValue(
      subject: true,
      student: true,
      schedule: true,
      target: true,
    );
    await renderTour(tester);
    expect(find.text('1/5'), findsNothing);
    expect(repository.saves, isEmpty);
    expect(find.byType(TutorialCompletionSheet), findsNothing);
  });

  for (final dismissal in ['artwork tap', 'outside tap', 'downward drag']) {
    testWidgets(
      'final success sheet and confetti open together and close by $dismissal',
      (tester) async {
        repository.value = guideValue(
          subject: true,
          student: true,
          schedule: true,
        );
        await renderTour(tester, finalTarget: true);
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const ValueKey('tutorial-next')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Tunjukkan tombol simpan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simpan'));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('tutorial-completion-sheet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('tutorial-completion-confetti')),
          findsOneWidget,
        );
        expect(cubit.state.value!.remainingCount, 0);
        final artwork = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  TutorialCompletionSheet.artwork,
        );
        expect(artwork, findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
        await tester.pumpAndSettle();
        final sheetState = tester.state(find.byType(NalaraCelebrationSheet));
        await cubit.load();
        await tester.pump();
        expect(
          tester.state(find.byType(NalaraCelebrationSheet)),
          same(sheetState),
        );
        switch (dismissal) {
          case 'artwork tap':
            await tester.tap(artwork);
          case 'outside tap':
            await tester.tapAt(const Offset(12, 12));
          case 'downward drag':
            await tester.drag(
              find.byKey(const ValueKey('tutorial-completion-drag-handle')),
              const Offset(0, 550),
            );
        }
        await tester.pumpAndSettle();
        expect(find.byType(TutorialCompletionSheet), findsNothing);
        expect(
          find.byKey(const ValueKey('tutorial-completion-confetti')),
          findsNothing,
        );
        expect(cubit.state.value!.remainingCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('editing hint provides an Overlay for the skip tooltip', (
    tester,
  ) async {
    repository.value = guideValue(subject: true);
    await renderTour(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('tutorial-next')));
      await tester.pumpAndSettle();
    }
    final skip = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Lewati panduan',
    );
    expect(skip, findsOneWidget);
    expect(Overlay.maybeOf(tester.element(skip)), isNotNull);
    await tester.longPress(skip);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(skip);
    await tester.pumpAndSettle();
    expect(skip, findsNothing);
    expect(cubit.state.value!.remainingCount, 3);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'checklist starts an unfinished tutorial and has no Home toggles',
    (tester) async {
      repository.value = guideValue(
        subject: true,
        student: true,
        schedule: true,
      );
      await cubit.load();
      TeachingGuideStep? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TeachingGuideCard(
                cubit: cubit,
                onOpen: (_) {},
                onStart: (step) => selected = step,
              ),
            ),
          ),
        ),
      );
      final next = find.byKey(const ValueKey('teaching-guide-next'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      expect(selected, TeachingGuideStep.target);
      expect(cubit.state.value!.remainingCount, 1);
      expect(find.textContaining('di Beranda'), findsNothing);
    },
  );

  testWidgets('session guidance follows recorded attendance and reports', (
    tester,
  ) async {
    Future<void> render(bool attendance, bool report) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionTeachingGuide(
            attendanceRecorded: attendance,
            reportPublished: report,
          ),
        ),
      ),
    );
    await render(false, false);
    expect(
      find.textContaining('Setelah pertemuan berlangsung'),
      findsOneWidget,
    );
    await render(true, false);
    expect(find.textContaining('Presensi sudah dicatat'), findsOneWidget);
    await render(true, true);
    expect(find.text('Panduan sesi'), findsNothing);
  });
}
