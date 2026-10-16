import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/repositories/learning_repository.dart';
import 'package:nalara/features/learning_goals/domain/usecases/update_progress.dart';
import 'package:nalara/features/learning_goals/presentation/pages/learning_pages.dart';
import 'package:nalara/features/learning_goals/presentation/widgets/learning_plans_style.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'learning_plans_fixtures.dart';

void main() {
  late LearningRepositoryFake repository;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    repository = LearningRepositoryFake();
    getIt.registerSingleton<LearningRepository>(repository);
    getIt.registerSingleton(PlanProgressLabel());
  });
  tearDown(() => getIt.reset());
  void viewport(WidgetTester tester, [Size size = const Size(390, 844)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(
    WidgetTester tester, {
    double scale = 1,
    String? studentId,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 24, bottom: 18),
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: LearningPlansPage(studentId: studentId),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('mockup header, original empty target asset and one pill CTA', (
    tester,
  ) async {
    viewport(tester);
    await render(tester);
    expect(find.text('Target belajar'), findsOneWidget);
    expect(
      find.text('Kelola rencana dan target belajar siswa'),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.text('Target belajar')).top,
      greaterThanOrEqualTo(24),
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      LearningPlansStyle.cream,
    );
    expect(find.byTooltip('Muat ulang target'), findsOneWidget);
    expect(find.byTooltip('Kembali ke siswa'), findsNothing);
    expect(repository.calls.single, (page: 1, studentId: null));
    expect(find.text('Belum ada rencana belajar.'), findsOneWidget);
    expect(
      find.text(
        'Mulai dengan menentukan periode dan target belajar untuk siswa.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Image>(find.byKey(const ValueKey('target-empty-artwork')))
          .image,
      isA<AssetImage>().having(
        (asset) => asset.assetName,
        'original asset',
        'assets/Empty/Empty target.png',
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('target-empty-artwork'))).width,
      240,
      reason: 'Ukuran ilustrasi sama dengan empty Jadwal kosong.',
    );
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('target-add-empty')),
    );
    expect(button.style!.shape!.resolve({}), isA<StadiumBorder>());
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.byTooltip('Muat ulang target'));
    await tester.pumpAndSettle();
    expect(repository.calls.length, 2);
    await tester.drag(
      find.byKey(const ValueKey('target-scroll')),
      const Offset(0, 350),
    );
    await tester.pumpAndSettle();
    expect(repository.calls.length, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'loading and verbatim backend error never appear as empty success',
    (tester) async {
      viewport(tester);
      final pending = Completer<PageResult<LearningPlan>>();
      repository.respond = (_) => pending.future;
      await render(tester, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const ValueKey('target-empty-artwork')), findsNothing);
      const message = 'Data target belum dapat diakses. Silakan coba kembali.';
      pending.completeError(const AppFailure(message));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(find.byKey(const ValueKey('target-add-empty')), findsNothing);
      repository.respond = null;
      await tester.tap(find.byKey(const ValueKey('target-retry')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('target-empty-artwork')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'real plan fields, null versus zero progress, load more/error/retry and populated add',
    (tester) async {
      viewport(tester);
      repository.records = [
        planFixture('a', progress: null),
        planFixture('b', progress: 0),
      ];
      repository.limit = 1;
      await render(tester);
      expect(find.text('Rencana a'), findsOneWidget);
      expect(find.text('Alya · Matematika'), findsOneWidget);
      expect(find.text('12 Okt 2026 – 18 Okt 2026'), findsOneWidget);
      expect(find.text('Belum ada target'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('target-empty-artwork')), findsNothing);
      expect(find.byKey(const ValueKey('target-add-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('target-load-more')), findsOneWidget);
      repository.error = const AppFailure(
        'Tidak dapat memuat halaman berikutnya',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('target-load-more')),
      );
      await tester.tap(find.byKey(const ValueKey('target-load-more')));
      await tester.pumpAndSettle();
      expect(
        find.text('Tidak dapat memuat halaman berikutnya'),
        findsOneWidget,
      );
      expect(find.text('Rencana a'), findsOneWidget);
      repository.error = null;
      await tester.ensureVisible(find.byKey(const ValueKey('target-retry')));
      await tester.tap(find.byKey(const ValueKey('target-retry')));
      await tester.pumpAndSettle();
      expect(repository.calls.last.page, 2);
      expect(find.text('Rencana b'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );
      expect(find.text('Rencana a'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'scoped empty action opens existing form; form/detail return refreshes backend',
    (tester) async {
      viewport(tester);
      final router = GoRouter(
        initialLocation: '/teacher/students/s1/progress',
        routes: [
          GoRoute(
            path: '/teacher/students/s1/progress',
            builder: (_, _) => const LearningPlansPage(studentId: 's1'),
          ),
          GoRoute(
            path: '/teacher/targets/new',
            builder: (_, state) => Scaffold(
              body: Text('Form ${state.uri.queryParameters['studentId']}'),
            ),
          ),
          GoRoute(
            path: '/teacher/plans/a',
            builder: (_, _) => const Scaffold(body: Text('Detail rencana')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Kembali ke siswa'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('target-add-empty')),
      );
      await tester.tap(find.byKey(const ValueKey('target-add-empty')));
      await tester.pumpAndSettle();
      expect(find.text('Form s1'), findsOneWidget);
      repository.records = [planFixture('a')];
      router.pop();
      await tester.pumpAndSettle();
      expect(repository.calls.last, (page: 1, studentId: 's1'));
      await tester.tap(find.text('Rencana a'));
      await tester.pumpAndSettle();
      expect(find.text('Detail rencana'), findsOneWidget);
      repository.records = [planFixture('a', progress: 60)];
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('60%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('target-add-list')));
      await tester.pumpAndSettle();
      expect(find.text('Form s1'), findsOneWidget);
    },
  );

  testWidgets(
    'scope change on the same widget cannot display the old response',
    (tester) async {
      viewport(tester);
      final old = Completer<PageResult<LearningPlan>>();
      repository.respond = (_) => old.future;
      await render(tester, studentId: 's1', settle: false);
      repository.respond = null;
      repository.records = [planFixture('b', studentId: 's2')];
      await render(tester, studentId: 's2');
      old.complete(
        PageResult(items: [planFixture('old')], total: 1, page: 1, limit: 30),
      );
      await tester.pumpAndSettle();
      expect(repository.calls.last.studentId, 's2');
      expect(find.text('Rencana b'), findsOneWidget);
      expect(find.text('Rencana old'), findsNothing);
    },
  );

  testWidgets('320px and enlarged text remain scrollable inside safe area', (
    tester,
  ) async {
    viewport(tester, const Size(320, 568));
    await render(tester, scale: 2);
    await tester.ensureVisible(find.byKey(const ValueKey('target-add-empty')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('target-add-empty')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    repository.records = [planFixture('a')];
    await tester.ensureVisible(find.byTooltip('Muat ulang target'));
    await tester.tap(find.byTooltip('Muat ulang target'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('target-load-more')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
