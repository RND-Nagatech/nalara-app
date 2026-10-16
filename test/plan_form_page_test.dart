import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/repositories/learning_repository.dart';
import 'package:nalara/features/learning_goals/presentation/pages/learning_pages.dart';
import 'package:nalara/features/learning_goals/presentation/widgets/plan_form_style.dart';
import 'package:nalara/features/learning_goals/presentation/widgets/plan_period_field.dart';
import 'package:nalara/features/schedules/domain/usecases/load_teaching_options.dart';
import 'package:nalara/features/subjects/domain/entities/subject.dart';
import 'package:nalara/shared/domain/teaching_catalog_changes.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/widgets/nalara_dropdown.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/date_time_utils.dart';
import 'package:nalara/utils/injector.dart';
import 'learning_plans_fixtures.dart';
import 'plan_form_fixtures.dart';
import 'students_fixtures.dart';

void main() {
  late StudentsRepositoryFake students;
  late PlanSubjectsFake subjects;
  late PlanOptionsFake options;
  late PlanRepositoryFake repository;
  late TeachingCatalogChanges catalog;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    students = StudentsRepositoryFake()
      ..records = [studentFixture('s1', 'Alya'), studentFixture('s2', 'Bima')]
      ..limit = 1;
    subjects = PlanSubjectsFake();
    options = PlanOptionsFake(students, subjects);
    repository = PlanRepositoryFake();
    catalog = TeachingCatalogChanges();
    getIt.registerSingleton<LearningRepository>(repository);
    getIt.registerSingleton<LoadTeachingOptions>(options);
    getIt.registerSingleton(catalog);
  });
  tearDown(() async {
    await getIt.reset();
    await catalog.close();
  });
  void viewport(WidgetTester tester, [Size size = const Size(430, 1000)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder byId(String id) => find.byKey(ValueKey(id));
  TextField input(WidgetTester tester, String id) => tester.widget<TextField>(
    find.descendant(of: byId(id), matching: find.byType(TextField)),
  );
  Future<void> enter(WidgetTester tester, String id, String value) async {
    await tester.ensureVisible(byId(id));
    await tester.enterText(byId(id), value);
    await tester.pump();
  }

  Future<void> choose(WidgetTester tester, String id, String label) async {
    await tester.ensureVisible(byId(id));
    await tester.tap(byId(id));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String id, {bool settle = true}) async {
    await tester.ensureVisible(byId(id));
    await tester.tap(byId(id));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> render(
    WidgetTester tester, {
    String? studentId,
    String? sourceId,
    double scale = 1,
    double keyboard = 0,
    bool settle = true,
    GoRouter? router,
  }) async {
    Widget inset(BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.only(top: 28, bottom: 18),
        viewInsets: EdgeInsets.only(bottom: keyboard),
        textScaler: TextScaler.linear(scale),
      ),
      child: child!,
    );
    await tester.pumpWidget(
      router == null
          ? MaterialApp(
              theme: buildAppTheme(),
              builder: inset,
              home: PlanFormPage(
                studentId: studentId,
                sourceTargetId: sourceId,
              ),
            )
          : MaterialApp.router(
              theme: buildAppTheme(),
              builder: inset,
              routerConfig: router,
            ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  GoRouter routes({String initial = '/teacher/targets/new'}) {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/teacher/targets',
          builder: (_, _) => const Scaffold(body: Text('Daftar target')),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, state) => PlanFormPage(
                studentId: state.uri.queryParameters['studentId'],
                sourceTargetId: state.uri.queryParameters['sourceTargetId'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/teacher/plans/saved',
          builder: (_, _) => const Scaffold(body: Text('Rencana tersimpan')),
        ),
        GoRoute(
          path: '/teacher/subjects/new',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () {
                subjects.records = [
                  const Subject(id: 'new-subject', name: 'Renang'),
                ];
                context.pop();
              },
              child: const Text('Selesai tambah bidang'),
            ),
          ),
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
    'cream safe header, original artwork, external labels/counters and shared selectors',
    (tester) async {
      viewport(tester);
      await render(tester, studentId: 's2');
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        PlanFormStyle.cream,
      );
      expect(
        tester.getRect(byId('plan-form-back')).top,
        greaterThanOrEqualTo(28),
      );
      final art = tester.widget<Image>(byId('plan-form-artwork'));
      expect(
        (art.image as AssetImage).assetName,
        'assets/Empty/Empty target.png',
      );
      expect(art.fit, BoxFit.contain);
      expect(
        tester.getSize(byId('plan-form-artwork')).width,
        lessThanOrEqualTo(240),
      );
      expect(
        input(tester, 'plan-name').controller!.text,
        'Rencana belajar mingguan',
      );
      expect(input(tester, 'plan-name').maxLength, 200);
      expect(input(tester, 'plan-target-title-0').maxLength, 200);
      expect(input(tester, 'plan-target-description-0').maxLength, 3000);
      expect(input(tester, 'plan-target-criteria-0').maxLength, 1000);
      expect(
        input(tester, 'plan-target-title-0').decoration!.hintText,
        'Masukkan judul target',
      );
      expect(find.text('Target dalam periode ini'), findsOneWidget);
      expect(
        tester.widget<NalaraDropdown<String>>(byId('plan-student')).value,
        's2',
      );
      expect(
        tester
            .widget<NalaraDropdown<String>>(byId('plan-subject'))
            .options
            .length,
        2,
      );
      expect(
        tester.widget<TextButton>(byId('plan-target-remove-0')).onPressed,
        isNull,
      );
      expect(students.calls.map((call) => call.status), everyElement('active'));
      expect(repository.drafts, isEmpty);
    },
  );

  testWidgets(
    'add/remove uses stable controller/priority identity and keeps one target',
    (tester) async {
      viewport(tester);
      await render(tester);
      await enter(tester, 'plan-target-title-0', 'Target pertama');
      await tap(tester, 'plan-add-target');
      await enter(tester, 'plan-target-title-1', 'Target kedua');
      await choose(tester, 'plan-target-priority-1', 'Tinggi');
      await tap(tester, 'plan-target-remove-0');
      expect(byId('plan-target-title-0'), findsNothing);
      expect(
        input(tester, 'plan-target-title-1').controller!.text,
        'Target kedua',
      );
      expect(
        tester
            .state<FormFieldState<String>>(byId('plan-target-priority-1'))
            .value,
        'high',
      );
      expect(find.text('Target 1'), findsOneWidget);
      expect(
        tester.widget<TextButton>(byId('plan-target-remove-1')).onPressed,
        isNull,
      );
      await tap(tester, 'plan-add-target');
      expect(byId('plan-target-title-2'), findsOneWidget);
      expect(
        input(tester, 'plan-target-title-1').controller!.text,
        'Target kedua',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saves all targets once with actual IDs, priority and full WIB-day boundaries',
    (tester) async {
      viewport(tester);
      final router = routes(initial: '/teacher/targets/new?studentId=s2');
      await render(tester, router: router);
      await enter(tester, 'plan-target-title-0', 'Memahami pecahan');
      await enter(tester, 'plan-target-description-0', 'Latihan soal');
      await tap(tester, 'plan-add-target');
      await enter(tester, 'plan-target-title-1', 'Operasi pecahan');
      await enter(tester, 'plan-target-criteria-1', 'Selesai sepuluh soal');
      await choose(tester, 'plan-target-priority-1', 'Tinggi');
      await choose(tester, 'plan-subject', 'Piano');
      tester
          .widget<PlanPeriodField>(byId('plan-start'))
          .onChanged(DateTimeUtils.fromWallTime(DateTime(2026, 10, 15), 0, 0));
      await tester.pump();
      tester
          .widget<PlanPeriodField>(byId('plan-end'))
          .onChanged(DateTimeUtils.fromWallTime(DateTime(2026, 10, 21), 0, 0));
      await tester.pump();
      await tap(tester, 'plan-save');
      expect(find.text('Daftar target'), findsOneWidget);
      final draft = repository.drafts.single;
      expect(draft.studentId, 's2');
      expect(draft.subjectId, 'music');
      expect(draft.targets.map((t) => t.title), [
        'Memahami pecahan',
        'Operasi pecahan',
      ]);
      expect(draft.targets.first.description, 'Latihan soal');
      expect(draft.targets.last.successCriteria, 'Selesai sepuluh soal');
      expect(draft.targets.last.priority, 'high');
      expect(draft.startAt, DateTime.utc(2026, 10, 14, 17));
      expect(draft.endAt, DateTime.utc(2026, 10, 21, 16, 59, 59, 999, 999));
    },
  );

  testWidgets(
    'backend rejection is verbatim, duplicate save disabled and draft kept for retry',
    (tester) async {
      viewport(tester);
      await render(tester);
      await enter(tester, 'plan-target-title-0', 'Latihan membaca');
      final pending = Completer<LearningPlan>();
      repository.save = (_) => pending.future;
      await tap(tester, 'plan-save', settle: false);
      expect(tester.widget<FilledButton>(byId('plan-save')).onPressed, isNull);
      expect(
        tester.widget<OutlinedButton>(byId('plan-add-target')).onPressed,
        isNull,
      );
      expect(input(tester, 'plan-name').enabled, isFalse);
      expect(repository.drafts.length, 1);
      const message = 'Rencana tidak dapat disimpan. Siswa sudah diarsipkan.';
      pending.completeError(const AppFailure(message));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(
        input(tester, 'plan-target-title-0').controller!.text,
        'Latihan membaca',
      );
      expect(
        tester.widget<FilledButton>(byId('plan-save')).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'required fields and reversed period never send an incomplete draft',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tap(tester, 'plan-save');
      expect(find.text('Minimal 2 karakter'), findsOneWidget);
      expect(repository.drafts, isEmpty);
      await enter(tester, 'plan-target-title-0', 'Target valid');
      tester
          .widget<PlanPeriodField>(byId('plan-start'))
          .onChanged(DateTime.utc(2026, 10, 20));
      await tester.pump();
      tester
          .widget<PlanPeriodField>(byId('plan-end'))
          .onChanged(DateTime.utc(2026, 10, 10));
      await tester.pump();
      await tap(tester, 'plan-save');
      expect(find.text('Akhir periode harus setelah awal'), findsOneWidget);
      expect(repository.drafts, isEmpty);
    },
  );

  testWidgets(
    'continuation copies editable fields and starts next period without rewriting source progress',
    (tester) async {
      viewport(tester);
      await render(tester, sourceId: 't1');
      expect(find.text('Teruskan target'), findsOneWidget);
      expect(
        input(tester, 'plan-name').controller!.text,
        'Rencana belajar lanjutan',
      );
      expect(
        input(tester, 'plan-target-title-0').controller!.text,
        repository.source.title,
      );
      expect(
        tester.widget<NalaraDropdown<String>>(byId('plan-student')).value,
        's2',
      );
      expect(
        tester.widget<NalaraDropdown<String>>(byId('plan-subject')).value,
        'music',
      );
      expect(
        tester.widget<PlanPeriodField>(byId('plan-start')).value,
        DateTime.utc(2026, 10, 14, 17),
      );
      expect(
        tester.widget<PlanPeriodField>(byId('plan-end')).value,
        DateTime.utc(2026, 10, 20, 17),
      );
      expect(repository.source.progress, 60);
      expect(repository.drafts, isEmpty);
    },
  );

  testWidgets(
    'catalog refresh/error/retry preserves multi-target drafts and stable selected IDs',
    (tester) async {
      viewport(tester);
      await render(tester);
      await enter(tester, 'plan-name', 'Rencana draft');
      await enter(tester, 'plan-target-title-0', 'Target draft');
      await choose(tester, 'plan-subject', 'Piano');
      subjects.records = [
        const Subject(id: 'math', name: 'Matematika'),
        const Subject(id: 'music', name: 'Musik terbaru'),
      ];
      catalog.notifyChanged();
      await tester.pumpAndSettle();
      expect(input(tester, 'plan-name').controller!.text, 'Rencana draft');
      expect(
        input(tester, 'plan-target-title-0').controller!.text,
        'Target draft',
      );
      final selected = tester.widget<NalaraDropdown<String>>(
        byId('plan-subject'),
      );
      expect(selected.value, 'music');
      expect(selected.options.last.label, 'Musik terbaru');
      options.error = const AppFailure('Gagal memuat pilihan terbaru');
      catalog.notifyChanged();
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat pilihan terbaru'), findsOneWidget);
      expect(
        input(tester, 'plan-target-title-0').controller!.text,
        'Target draft',
      );
      expect(tester.widget<FilledButton>(byId('plan-save')).onPressed, isNull);
      options.error = null;
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(byId('plan-save')).onPressed,
        isNotNull,
      );
      expect(
        tester.widget<NalaraDropdown<String>>(byId('plan-subject')).value,
        'music',
      );
    },
  );

  testWidgets(
    'missing options can be created and returned without clearing existing draft',
    (tester) async {
      viewport(tester);
      subjects.records = [];
      final router = routes();
      await render(tester, router: router);
      expect(tester.widget<FilledButton>(byId('plan-save')).onPressed, isNull);
      await enter(tester, 'plan-name', 'Tetap tersimpan');
      await tester.ensureVisible(find.text('Tambah bidang belajar'));
      await tester.tap(find.text('Tambah bidang belajar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selesai tambah bidang'));
      await tester.pumpAndSettle();
      expect(input(tester, 'plan-name').controller!.text, 'Tetap tersimpan');
      expect(
        tester.widget<NalaraDropdown<String>>(byId('plan-subject')).value,
        'new-subject',
      );
      expect(
        tester.widget<FilledButton>(byId('plan-save')).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('loading/error/retry and rebuilds do not issue repeated loads', (
    tester,
  ) async {
    viewport(tester);
    final pending = Completer<TeachingOptions>();
    options.respond = () => pending.future;
    await render(tester, settle: false);
    expect(byId('plan-save'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(const AppFailure('Tidak dapat memuat siswa'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak dapat memuat siswa'), findsOneWidget);
    options.respond = null;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    final calls = options.calls;
    await render(tester);
    expect(options.calls, calls);
    expect(byId('plan-save'), findsOneWidget);
  });

  testWidgets(
    '320px/large text/keyboard stays scrollable and dates stack without artwork overlap',
    (tester) async {
      viewport(tester, const Size(320, 700));
      await render(tester, scale: 1.7, keyboard: 200);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(byId('plan-start'));
      await tester.pumpAndSettle();
      final start = tester.getRect(byId('plan-start')),
          end = tester.getRect(byId('plan-end'));
      expect(end.top, greaterThanOrEqualTo(start.bottom));
      await tester.ensureVisible(byId('plan-save'));
      await tester.pumpAndSettle();
      expect(tester.getRect(byId('plan-save')).bottom, lessThanOrEqualTo(500));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'regular width uses two date tiles and cancel keeps the selected day',
    (tester) async {
      viewport(tester);
      await render(tester);
      final start = tester.getRect(byId('plan-start')),
          end = tester.getRect(byId('plan-end'));
      expect(start.top, end.top);
      expect(end.left, greaterThan(start.right));
      final previous = tester.widget<PlanPeriodField>(byId('plan-start')).value;
      final button = find.descendant(
        of: byId('plan-start'),
        matching: find.byType(OutlinedButton),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      Navigator.of(tester.element(find.byType(DatePickerDialog))).pop();
      await tester.pumpAndSettle();
      expect(
        tester.widget<PlanPeriodField>(byId('plan-start')).value,
        previous,
      );
      expect(repository.drafts, isEmpty);
    },
  );

  testWidgets('removed choices retain their IDs until explicitly replaced', (
    tester,
  ) async {
    viewport(tester);
    await render(tester);
    await enter(tester, 'plan-target-title-0', 'Target tersimpan');
    await choose(tester, 'plan-subject', 'Piano');
    subjects.records = [const Subject(id: 'math', name: 'Matematika')];
    catalog.notifyChanged();
    await tester.pumpAndSettle();
    expect(
      tester.widget<NalaraDropdown<String>>(byId('plan-subject')).value,
      'music',
    );
    await tap(tester, 'plan-save');
    expect(find.text('Pilih bidang belajar yang tersedia.'), findsOneWidget);
    expect(repository.drafts, isEmpty);
    expect(
      input(tester, 'plan-target-title-0').controller!.text,
      'Target tersimpan',
    );
    await choose(tester, 'plan-subject', 'Matematika');
    expect(
      tester.widget<NalaraDropdown<String>>(byId('plan-subject')).value,
      'math',
    );
  });

  testWidgets(
    'scope changes reset the editor and pending loads after dispose are ignored',
    (tester) async {
      viewport(tester);
      await render(tester, studentId: 's1');
      await enter(tester, 'plan-name', 'Draft siswa lama');
      await render(tester, studentId: 's2');
      expect(
        tester.widget<NalaraDropdown<String>>(byId('plan-student')).value,
        's2',
      );
      expect(
        input(tester, 'plan-name').controller!.text,
        'Rencana belajar mingguan',
      );
      final pending = Completer<TeachingOptions>();
      options.respond = () => pending.future;
      catalog.notifyChanged();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete(const TeachingOptions([], []));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'back preserves target fallback and late save never opens another route',
    (tester) async {
      viewport(tester);
      final router = routes();
      await render(tester, router: router);
      await enter(tester, 'plan-target-title-0', 'Target tertunda');
      final pending = Completer<LearningPlan>();
      repository.save = (_) => pending.future;
      await tap(tester, 'plan-save', settle: false);
      router.push('/other');
      await tester.pump();
      pending.complete(planFixture('saved'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman lain'), findsOneWidget);
      expect(find.text('Rencana tersimpan'), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      await tap(tester, 'plan-form-back');
      expect(find.text('Daftar target'), findsOneWidget);
    },
  );
}
