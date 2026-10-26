import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/app.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/lesson_reports/data/datasources/reports_remote_source.dart';
import 'package:nalara/features/lesson_reports/data/repositories/reports_repository_impl.dart';
import 'package:nalara/features/lesson_reports/domain/entities/lesson_report.dart';
import 'package:nalara/features/lesson_reports/domain/repositories/reports_repository.dart';
import 'package:nalara/features/lesson_reports/presentation/pages/reports_pages.dart';
import 'package:nalara/features/parent_portal/presentation/pages/parent_shared_pages.dart';
import 'package:nalara/features/profile/presentation/pages/more_page.dart';
import 'package:nalara/features/student_portal/presentation/pages/student_pages.dart';
import 'package:nalara/features/subscription/domain/subscription.dart';
import 'package:nalara/features/subscription/domain/subscription_repository.dart';
import 'package:nalara/features/subscription/presentation/subscription_cubit.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/domain/teaching_catalog_changes.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

const _teacher = Teacher(
  id: 'teacher-a',
  name: 'Guru',
  email: 'guru@example.test',
  workspaceId: 'workspace-a',
  timezone: 'Asia/Jakarta',
);
const _draft = ReportDraft(
  topic: 'Topik',
  summary: 'Ringkasan',
  visibility: 'teacher',
);
const _report = LessonReport(
  id: 'report',
  sessionId: 'session',
  studentId: 'student',
  topic: 'Topik',
  summary: 'Ringkasan',
  observations: '',
  difficulties: '',
  homework: '',
  recommendation: '',
  visibility: 'teacher',
  status: 'draft',
  targetIds: [],
);

class _Auth extends Fake implements AuthRepository {
  Teacher? teacher = _teacher;
  @override
  Future<Teacher?> restore() async => teacher;
  @override
  Future<bool> onboardingSeen() async => true;
  @override
  Future<void> completeOnboarding() async {}
}

class _Reports extends Fake implements ReportsRepository {
  int total = 23, reads = 0;
  bool fail = false;
  final pending = <Completer<int>>[];
  final statuses = <String?>[];
  @override
  Future<int> draftCount() async {
    reads++;
    if (pending.isNotEmpty) return pending.removeAt(0).future;
    if (fail) throw Exception('Offline');
    return total;
  }

  @override
  Future<PageResult<LessonReport>> list({
    int page = 1,
    String? studentId,
    String? status,
    String? sessionId,
  }) async {
    statuses.add(status);
    return PageResult(items: [], total: 0, page: page, limit: 30);
  }
}

class _Remote extends Fake implements ReportsRemoteSource {
  Object? total = 89;
  bool fail = false;
  Map<String, dynamic>? query;
  Map<String, dynamic> get report => {
    '_id': 'report',
    'sessionId': 'session',
    'studentId': 'student',
    'topic': 'Topik',
    'summary': 'Ringkasan',
    'visibility': 'teacher',
    'status': 'draft',
  };
  @override
  Future<Map<String, dynamic>> list(Map<String, dynamic> query) async {
    this.query = query;
    return {'items': [], 'total': total, 'page': 1, 'limit': 1};
  }

  void check() {
    if (fail) throw Exception('Gagal');
  }

  @override
  Future<Map<String, dynamic>> create(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    check();
    return report;
  }

  @override
  Future<Map<String, dynamic>> createBatch(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    check();
    return {
      'items': [
        report,
        {...report, '_id': 'other'},
      ],
    };
  }

  @override
  Future<void> update(
    String sessionId,
    String id,
    Map<String, dynamic> data,
  ) async => check();
  @override
  Future<void> publish(String sessionId, String id) async => check();
}

class _SubscriptionRepository extends Fake implements SubscriptionRepository {}

class _Subscription extends SubscriptionCubit {
  _Subscription() : super(_SubscriptionRepository());
  void setActive(bool active) {
    accountId = _teacher.id;
    emit(
      SubscriptionState(
        value: TutorSubscription(
          plan: 'basic',
          status: active ? 'active' : 'expired',
          active: active,
          checkoutEnabled: false,
          daysRemaining: 1,
          activeStudents: 1,
          studentLimit: 30,
          trialDays: 0,
          endsAt: DateTime.utc(2099),
          serverNow: DateTime.utc(2026),
          features: [],
          featureLabels: {},
          plans: [],
        ),
      ),
    );
  }
}

void main() {
  late _Auth account;
  late AuthCubit auth;
  late _Reports reports;
  late TeachingCatalogChanges changes;
  final badge = find.byKey(const ValueKey('reports-draft-count'));

  setUp(() async {
    account = _Auth();
    auth = AuthCubit(account);
    await auth.restore();
    reports = _Reports();
    changes = TeachingCatalogChanges();
    getIt.registerSingleton(auth, dispose: (value) => value.close());
    getIt.registerSingleton<ReportsRepository>(reports);
    getIt.registerSingleton(changes, dispose: (value) => value.close());
  });
  tearDown(() => getIt.reset());

  Future<void> render(
    WidgetTester tester, {
    Widget? page,
    bool narrow = false,
  }) async {
    tester.view.physicalSize = narrow
        ? const Size(320, 640)
        : const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(narrow ? 2 : 1)),
          child: child!,
        ),
        home: page ?? const MorePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'count uses the server total, minimal draft query and rejects malformed totals',
    () async {
      final remote = _Remote();
      final repository = ReportsRepositoryImpl(remote);
      expect(
        await repository.draftCount(),
        89,
      ); // Items may be empty or just one row.
      expect(remote.query, {'page': 1, 'limit': 1, 'status': 'draft'});
      for (final invalid in [null, -1, '89', 1.5]) {
        remote.total = invalid;
        await expectLater(repository.draftCount(), throwsA(isA<Exception>()));
      }
    },
  );

  test(
    'confirmed single/batch/edit/publish writes invalidate once; failures do not',
    () async {
      final remote = _Remote();
      final repository = ReportsRepositoryImpl(remote, changes: changes);
      var events = 0;
      final subscription = changes.stream.listen((_) => events++);
      await repository.create('session', _draft);
      await repository.createBatch(
        'session',
        _draft,
        targetsBySession: {'session': [], 'other': []},
        publish: false,
      );
      await repository.update(_report, _draft);
      await repository.publish(_report);
      await Future<void>.delayed(Duration.zero);
      expect(events, 4);
      remote.fail = true;
      await expectLater(repository.publish(_report), throwsException);
      await expectLater(repository.create('session', _draft), throwsException);
      await Future<void>.delayed(Duration.zero);
      expect(events, 4);
      await subscription.cancel();
    },
  );

  testWidgets(
    'red badge counts all drafts, updates after writes and hides at zero',
    (tester) async {
      await render(tester);
      expect(badge, findsOneWidget);
      expect(find.text('23 laporan draf belum diterbitkan'), findsOneWidget);
      expect(reports.reads, 1);
      reports.total = 3;
      changes.notifyChanged();
      await tester.pumpAndSettle();
      expect(find.text('3 laporan draf belum diterbitkan'), findsOneWidget);
      reports.total = 0;
      changes.notifyChanged();
      await tester.pumpAndSettle();
      expect(badge, findsNothing);
      expect(
        find.text('Lihat dan kelola laporan perkembangan siswa'),
        findsOneWidget,
      );
    },
  );

  testWidgets('real menu route opens Draft and refreshes the count on return', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    addTearDown(router.dispose);
    addTearDown(refresh.dispose);
    router.go('/teacher/more');
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    final menu = find.byKey(const ValueKey('more-menu-reports'));
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters['status'], 'draft');
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    expect(reports.statuses, ['draft']);
    reports.total = 0;
    router.pop();
    await tester.pumpAndSettle();
    expect(badge, findsNothing);
    expect(reports.reads, greaterThanOrEqualTo(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'restoring the same teacher invalidates the previous session loader',
    (tester) async {
      final old = Completer<int>();
      reports.pending.add(old);
      await render(tester);
      reports.total = 5;
      await auth.restore();
      await tester.pumpAndSettle();
      old.complete(99);
      await tester.pumpAndSettle();
      expect(find.text('5 laporan draf belum diterbitkan'), findsOneWidget);
      expect(find.text('99'), findsNothing);
    },
  );

  testWidgets('account changes discard late totals from the previous teacher', (
    tester,
  ) async {
    final old = Completer<int>();
    reports.pending.add(old);
    await render(tester);
    expect(badge, findsNothing);
    account.teacher = const Teacher(
      id: 'teacher-b',
      name: 'Guru B',
      email: 'b@example.test',
      workspaceId: 'workspace-b',
      timezone: 'Asia/Jakarta',
    );
    reports.total = 2;
    await auth.restore();
    await tester.pumpAndSettle();
    expect(find.text('2 laporan draf belum diterbitkan'), findsOneWidget);
    old.complete(800);
    await tester.pumpAndSettle();
    expect(find.text('2 laporan draf belum diterbitkan'), findsOneWidget);
    expect(find.text('800'), findsNothing);
    auth.expire();
    await tester.pumpAndSettle();
    expect(badge, findsNothing);
  });

  testWidgets(
    'newer reload wins; error does not show a stale count or false zero',
    (tester) async {
      await render(tester);
      final old = Completer<int>();
      reports.pending.add(old);
      changes.notifyChanged();
      await tester.pump();
      reports.total = 2;
      changes.notifyChanged();
      await tester.pumpAndSettle();
      old.complete(90);
      await tester.pumpAndSettle();
      expect(find.text('2 laporan draf belum diterbitkan'), findsOneWidget);
      reports.fail = true;
      changes.notifyChanged();
      await tester.pumpAndSettle();
      expect(badge, findsNothing);
      expect(
        find.textContaining('Jumlah draf belum dapat dimuat'),
        findsOneWidget,
      );
    },
  );

  testWidgets('resume refreshes; late completion after dispose is ignored', (
    tester,
  ) async {
    await render(tester);
    reports.total = 4;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('4 laporan draf belum diterbitkan'), findsOneWidget);
    final late = Completer<int>();
    reports.pending.add(late);
    changes.notifyChanged();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    late.complete(70);
    changes.notifyChanged();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'checking or expired subscription does not trigger a count request/paywall',
    (tester) async {
      final subscription = _Subscription();
      getIt.registerSingleton<SubscriptionCubit>(
        subscription,
        dispose: (value) => value.close(),
      );
      await render(tester);
      expect(reports.reads, 0);
      subscription.setActive(false);
      await tester.pumpAndSettle();
      expect(reports.reads, 0);
      subscription.setActive(true);
      await tester.pumpAndSettle();
      expect(badge, findsOneWidget);
      subscription.setActive(false);
      await tester.pumpAndSettle();
      expect(badge, findsNothing);
    },
  );

  for (final page in [const ParentSharedMorePage(), const StudentMorePage()]) {
    testWidgets(
      '${page.runtimeType} never loads or displays teacher draft counts',
      (tester) async {
        await render(tester, page: page);
        expect(badge, findsNothing);
        expect(reports.reads, 0);
      },
    );
  }

  testWidgets('long count and large text remain readable in the compact menu', (
    tester,
  ) async {
    reports.total = 12345;
    await render(tester, narrow: true);
    final menu = find.byKey(const ValueKey('more-menu-reports'));
    await tester.scrollUntilVisible(menu, 200);
    await tester.pumpAndSettle();
    expect(badge, findsOneWidget);
    expect(find.text('12345 laporan draf belum diterbitkan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'read-only report list ignores a draft query and uses its portal loader',
    (tester) async {
      var portalReads = 0;
      await render(
        tester,
        page: ReportsPage(
          readOnly: true,
          routePrefix: '/parent',
          initialStatus: 'draft',
          loadReports: (page, studentId) async {
            portalReads++;
            return PageResult(items: [], total: 0, page: page, limit: 30);
          },
        ),
      );
      expect(find.text('Draft'), findsNothing);
      expect(portalReads, 1);
      expect(reports.statuses, isEmpty);
    },
  );
}
