import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/learning_goals/domain/usecases/update_progress.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/domain/entities/student_summary.dart';
import 'package:nalara/features/students/domain/repositories/students_repository.dart';
import 'package:nalara/features/students/domain/usecases/load_student_overview.dart';
import 'package:nalara/features/students/presentation/pages/students_pages.dart';
import 'package:nalara/features/students/presentation/widgets/student_detail_style.dart';
import 'package:nalara/features/access/presentation/widgets/referral_invitation_widgets.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'learning_plans_fixtures.dart';
import 'schedule_fixtures.dart';
import 'student_detail_fixtures.dart';
import 'tuition_fixtures.dart';
import 'package:nalara/features/tuition_fees/domain/tuition_repository.dart';

void main() {
  late DetailFixtures fixtures;
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    fixtures = DetailFixtures();
    getIt.registerSingleton<StudentsRepository>(fixtures.students);
    getIt.registerSingleton<LoadStudentOverview>(fixtures.load);
    getIt.registerSingleton(PlanProgressLabel());
    getIt.registerSingleton<TuitionRepository>(TuitionFake());
  });
  tearDown(() => getIt.reset());
  void viewport(WidgetTester tester, [Size size = const Size(430, 1000)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder key(String id) => find.byKey(ValueKey('student-$id'));
  Future<void> render(
    WidgetTester tester, {
    String id = 's1',
    double scale = 1,
    bool settle = true,
    String? initialTab,
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
        home: StudentDetailPage(id: id, initialTab: initialTab),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tuition notification opens the fee tab without marking a payment',
    (tester) async {
      viewport(tester);
      await render(tester, initialTab: 'tuition');
      final tabs = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabs.controller!.index, 5);
      expect(find.text('Tandai lunas'), findsNothing);
      expect(find.text('Atur biaya bimbel'), findsOneWidget);
    },
  );

  Future<void> drainNotice(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> selectTab(WidgetTester tester, int index) async {
    final tab = find.byKey(ValueKey('student-tab-$index'));
    await tester.ensureVisible(tab);
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  Future<GoRouter> routed(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/teacher/students/s1',
      routes: [
        GoRoute(
          path: '/teacher/students',
          builder: (_, _) => const Scaffold(body: Text('Daftar siswa')),
        ),
        GoRoute(
          path: '/teacher/students/s1',
          builder: (_, _) => const StudentDetailPage(id: 's1'),
        ),
        for (final target in [
          'students/s1/edit',
          'plans/p1',
          'sessions/lesson',
          'reports/r1',
          'families',
          'families/f1',
        ])
          GoRoute(
            path: '/teacher/$target',
            builder: (_, _) => Scaffold(body: Text('Tujuan $target')),
          ),
        GoRoute(
          path: '/teacher/targets/new',
          builder: (_, state) => Scaffold(
            body: Text(
              'Rencana untuk ${state.uri.queryParameters['studentId']}',
            ),
          ),
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

  test(
    'domain loader keeps student scope, canonical null progress and immutable list snapshots',
    () async {
      fixtures.learning.records = [planFixture('p1', progress: null)];
      fixtures.schedules.records = [agendaLesson('lesson', 15)];
      fixtures.reports.records = [detailReport];
      final data = await fixtures.load('s1');
      expect(data.student.name, 'Alya');
      expect(fixtures.learning.calls.single.studentId, 's1');
      expect(fixtures.schedules.studentIds, ['s1']);
      expect(fixtures.reports.studentIds, ['s1']);
      expect(fixtures.students.requests, [
        'get:s1',
        'summary:s1',
        'invitations:s1',
      ]);
      expect(data.plans.single.progress, isNull);
      expect(() => data.plans.clear(), throwsUnsupportedError);
      expect(() => data.lessons.clear(), throwsUnsupportedError);
      expect(() => data.reports.clear(), throwsUnsupportedError);
      expect(() => data.invitations.clear(), throwsUnsupportedError);
    },
  );

  testWidgets(
    'preserved profile, seven tabs, canonical summary and no duplicate student information',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Detail siswa'), findsOneWidget);
      expect(tester.getRect(key('detail-back')).top, greaterThanOrEqualTo(28));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        StudentDetailStyle.cream,
      );
      expect(find.text('Alya'), findsOneWidget);
      expect(find.text('Kelas 5'), findsOneWidget);
      expect(find.text('Suka membaca'), findsOneWidget);
      expect(tester.widget<Text>(key('status')).data, 'Aktif');
      expect(
        tester.widget<Image>(key('detail-artwork')).image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'asset',
          'assets/Icon/Icon lainnya.png',
        ),
      );
      expect(find.text('Informasi siswa'), findsNothing);
      expect(tester.widget<Text>(key('overall-progress')).data, '53%');
      expect(tester.widget<Text>(key('weekly-progress')).data, '60%');
      expect(find.text('3 dari 5 target selesai'), findsOneWidget);
      expect(key('progress-chart'), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(7));
      for (final entry in [
        (index: 1, id: 'plans-card'),
        (index: 2, id: 'sessions-card'),
        (index: 3, id: 'reports-card'),
        (index: 4, id: 'family-card'),
        (index: 6, id: 'referral-card'),
      ]) {
        await selectTab(tester, entry.index);
        expect(key(entry.id), findsOneWidget);
      }
      expect(key('create-code'), findsOneWidget);
      expect(
        fixtures.students.requests
            .where((request) => request == 'get:s1')
            .length,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('swiping synchronizes tabs without reloading student data', (
    tester,
  ) async {
    viewport(tester);
    await render(tester);
    await tester.drag(key('detail-tab-view'), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    expect(key('plans-card'), findsOneWidget);
    await tester.drag(key('detail-tab-view'), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 2);
    expect(key('sessions-card'), findsOneWidget);
    expect(
      fixtures.students.requests.where((call) => call == 'get:s1').length,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  for (final progress in <int?>[null, 0]) {
    testWidgets(
      'summary distinguishes $progress progress and never invents history',
      (tester) async {
        viewport(tester);
        fixtures.students.summaryData = StudentSummary(
          studentId: 's1',
          timezone: 'Asia/Jakarta',
          generatedAt: DateTime.utc(2026, 10, 15),
          progress: progress,
          targetCount: progress == null ? 0 : 2,
          weekStartDate: '2026-10-12',
          weekEndDate: '2026-10-18',
          weeklyTargetCount: 0,
          weeklyCompletedCount: 0,
          weeklyCompletionProgress: null,
          trend: [],
        );
        await render(tester);
        expect(
          tester.widget<Text>(key('overall-progress')).data,
          progress == null ? '—' : '0%',
        );
        expect(key('progress-chart'), findsNothing);
        expect(key('weekly-progress'), findsNothing);
        expect(find.text('Belum ada target pada minggu ini.'), findsOneWidget);
        expect(
          find.text(
            progress == null
                ? 'Belum ada target yang dapat dihitung.'
                : 'Belum ada riwayat perubahan progres.',
          ),
          findsOneWidget,
        );
        expect(find.text('Informasi siswa'), findsNothing);
      },
    );
  }

  testWidgets(
    'list pagination survives tab switches without changing canonical summary',
    (tester) async {
      viewport(tester);
      fixtures.learning
        ..limit = 1
        ..records = [planFixture('p1'), planFixture('p2'), planFixture('p3')];
      await render(tester);
      await selectTab(tester, 1);
      await tap(tester, key('plans-load-more'));
      expect(key('plan-p2'), findsOneWidget);
      expect(key('plan-p1'), findsOneWidget);
      await selectTab(tester, 0);
      expect(tester.widget<Text>(key('overall-progress')).data, '53%');
      await selectTab(tester, 1);
      expect(key('plan-p2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading/error are not empty data; retry and pull refresh reload the domain loader',
    (tester) async {
      viewport(tester);
      final pending = Completer<Student>();
      fixtures.students.respondGet = (_) => pending.future;
      await render(tester, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(key('profile-card'), findsNothing);
      pending.completeError(
        const AppFailure(
          'Akses data siswa belum tersedia. Silakan coba kembali.',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Akses data siswa belum tersedia. Silakan coba kembali.'),
        findsOneWidget,
      );
      expect(find.text('Belum ada sesi les.'), findsNothing);
      fixtures.students.respondGet = null;
      await tap(tester, find.text('Coba lagi'));
      expect(key('profile-card'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('student-detail-scroll-s1')),
        const Offset(0, 350),
      );
      await tester.pumpAndSettle();
      expect(
        fixtures.students.requests.where((call) => call == 'get:s1').length,
        3,
      );
    },
  );

  testWidgets(
    'populated plans/sessions/reports use actual routes and refresh after returning',
    (tester) async {
      viewport(tester);
      fixtures.learning.records = [planFixture('p1', progress: null)];
      fixtures.schedules.records = [agendaLesson('lesson', 15)];
      fixtures.reports.records = [detailReport];
      final router = await routed(tester);
      for (final route in [
        (id: 'edit-profile', label: 'Tujuan students/s1/edit', tab: 0),
        (id: 'plan-p1', label: 'Tujuan plans/p1', tab: 1),
        (id: 'session-lesson', label: 'Tujuan sessions/lesson', tab: 2),
        (id: 'report-r1', label: 'Tujuan reports/r1', tab: 3),
        (id: 'create-plan', label: 'Rencana untuk s1', tab: 1),
        (id: 'open-family', label: 'Tujuan families', tab: 4),
      ]) {
        await selectTab(tester, route.tab);
        await tap(tester, key(route.id));
        expect(find.text(route.label), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
      }
      expect(
        fixtures.students.requests.where((call) => call == 'get:s1').length,
        7,
      );
      fixtures.students.current = detailStudent(familyId: 'f1');
      await tap(tester, key('edit-profile'));
      router.pop();
      await tester.pumpAndSettle();
      await tap(tester, key('open-family'));
      expect(find.text('Tujuan families/f1'), findsOneWidget);
    },
  );

  testWidgets(
    'referral replaces one latest card and a previously used code stays revocable',
    (tester) async {
      viewport(tester);
      fixtures.students.codes = [
        ParentInvitation(id: 'latest', lastUsedAt: DateTime.utc(2026, 10, 19)),
        ParentInvitation(id: 'old', revokedAt: DateTime.utc(2026, 10, 18)),
      ];
      await render(tester);
      await selectTab(tester, 6);
      expect(find.byType(ReferralInvitationTile), findsOneWidget);
      expect(find.byKey(const ValueKey('latest')), findsOneWidget);
      expect(find.byKey(const ValueKey('old')), findsNothing);
      expect(find.text('Berlaku tanpa batas waktu'), findsOneWidget);
      expect(find.text('Cabut kode'), findsOneWidget);
      for (var index = 0; index < 2; index++) {
        await tap(tester, key('create-code'));
        await tap(tester, find.text('Tutup'));
        expect(find.byType(ReferralInvitationTile), findsOneWidget);
        expect(find.byKey(const ValueKey('latest')), findsNothing);
        expect(find.byKey(const ValueKey('code')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'referral creation displays only the newly returned code; revocation keeps confirmation',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('NL-TEST-STUDENT'), findsNothing);
      await selectTab(tester, 6);
      await tap(tester, key('create-code'));
      expect(fixtures.students.requests, contains('invite:s1'));
      expect(find.text('NL-TEST-STUDENT'), findsOneWidget);
      await tap(tester, find.text('Tutup'));
      expect(find.text('NL-TEST-STUDENT'), findsNothing);
      await tap(tester, find.text('Cabut kode'));
      await tap(tester, find.text('Batal'));
      expect(fixtures.students.requests, isNot(contains('revoke:s1:code')));
      await tap(tester, find.text('Cabut kode'));
      await tap(tester, find.text('Lanjutkan'));
      expect(fixtures.students.requests, contains('revoke:s1:code'));
      expect(find.text('Dicabut'), findsOneWidget);
    },
  );

  testWidgets(
    'access revocation and archive preserve confirmations, real status and archived restrictions',
    (tester) async {
      viewport(tester);
      await render(tester);
      await selectTab(tester, 6);
      await tap(tester, key('revoke-access'));
      expect(fixtures.students.requests, isNot(contains('revoke-access:s1')));
      await tap(tester, find.text('Lanjutkan'));
      await drainNotice(tester);
      expect(fixtures.students.requests, contains('revoke-access:s1'));
      await selectTab(tester, 0);
      await tap(tester, key('archive'));
      await tap(tester, find.text('Lanjutkan'));
      await drainNotice(tester);
      expect(tester.widget<Text>(key('status')).data, 'Diarsipkan');
      expect(key('create-code'), findsNothing);
      expect(key('create-plan'), findsNothing);
      expect(key('archive'), findsNothing);
      await selectTab(tester, 6);
      expect(key('create-code'), findsNothing);
      expect(key('revoke-access'), findsOneWidget);
    },
  );

  testWidgets(
    'mutation backend error is displayed unchanged, without hiding profile data',
    (tester) async {
      viewport(tester);
      fixtures.students.actionError = const AppFailure(
        'Kode referral belum dapat dibuat. Silakan coba kembali.',
      );
      await render(tester);
      await selectTab(tester, 6);
      await tap(tester, key('create-code'));
      await drainNotice(tester);
      expect(
        find.text('Kode referral belum dapat dibuat. Silakan coba kembali.'),
        findsOneWidget,
      );
      expect(key('profile-card'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'long profile/large text/320px can scroll to every action; rebuild does not refetch',
    (tester) async {
      viewport(tester, const Size(320, 568));
      fixtures.students.current = detailStudent(
        name: 'Nama siswa yang cukup panjang untuk dua baris',
        notes: 'Catatan belajar yang panjang. ' * 16,
      );
      await render(tester, scale: 2);
      await selectTab(tester, 6);
      await tester.ensureVisible(key('revoke-access'));
      await tester.pumpAndSettle();
      expect(key('revoke-access').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await render(tester, scale: 1);
      expect(
        fixtures.students.requests.where((call) => call == 'get:s1').length,
        1,
      );
    },
  );

  testWidgets(
    'scope change and disposal ignore late data; direct back falls back to students',
    (tester) async {
      viewport(tester);
      final old = Completer<Student>();
      fixtures.students.respondGet = (_) => old.future;
      await render(tester, settle: false);
      fixtures.students.respondGet = null;
      fixtures.students.current = detailStudent(id: 's2', name: 'Bima');
      await render(tester, id: 's2');
      old.complete(detailStudent());
      await tester.pumpAndSettle();
      expect(find.text('Bima'), findsOneWidget);
      expect(find.text('Alya'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      fixtures.students.current = detailStudent();
      await routed(tester);
      await tap(tester, key('detail-back'));
      expect(find.text('Daftar siswa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pending code creation blocks duplicate submits and ignores a disposed page',
    (tester) async {
      viewport(tester);
      final pending = Completer<ParentInvitation>();
      fixtures.students.respondInvite = () => pending.future;
      await render(tester);
      await selectTab(tester, 6);
      await tester.ensureVisible(key('create-code'));
      await tester.tap(key('create-code'));
      await tester.pump();
      expect(tester.widget<FilledButton>(key('create-code')).onPressed, isNull);
      expect(
        tester.widget<OutlinedButton>(key('revoke-access')).onPressed,
        isNull,
      );
      expect(
        fixtures.students.requests.where((call) => call == 'invite:s1').length,
        1,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete(
        ParentInvitation(
          id: 'late',
          token: 'NL-LATE',
          expiresAt: DateTime.utc(2035),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NL-LATE'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late referral response never opens its code above another detail tab',
    (tester) async {
      viewport(tester);
      final pending = Completer<ParentInvitation>();
      fixtures.students.respondInvite = () => pending.future;
      await render(tester);
      await selectTab(tester, 6);
      await tester.ensureVisible(key('create-code'));
      await tester.tap(key('create-code'));
      await tester.pump();
      final tabs = tester.widget<TabBar>(find.byType(TabBar)).controller!;
      tabs.animateTo(0);
      // Do not settle an intentionally pending submission spinner.
      await tester.pump(const Duration(milliseconds: 400));
      pending.complete(
        ParentInvitation(
          id: 'late',
          token: 'NL-LATE',
          expiresAt: DateTime.utc(2035),
        ),
      );
      await tester.pumpAndSettle();
      expect(tabs.index, 0);
      expect(find.text('NL-LATE'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(key('overall-summary'), findsOneWidget);
    },
  );

  testWidgets(
    'a completed referral request does not open its code above another route',
    (tester) async {
      viewport(tester);
      final pending = Completer<ParentInvitation>();
      fixtures.students.respondInvite = () => pending.future;
      final router = await routed(tester);
      await selectTab(tester, 6);
      await tester.ensureVisible(key('create-code'));
      await tester.tap(key('create-code'));
      await tester.pump();
      router.push('/teacher/students/s1/edit');
      await tester.pumpAndSettle();
      pending.complete(
        ParentInvitation(
          id: 'late',
          token: 'NL-LATE',
          expiresAt: DateTime.utc(2035),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tujuan students/s1/edit'), findsOneWidget);
      expect(find.text('NL-LATE'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
