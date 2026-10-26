import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/widgets/nalara_dropdown.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/entities/session_overview.dart';
import 'package:nalara/features/schedules/presentation/widgets/session_detail_style.dart';
import 'package:nalara/features/parent_portal/domain/repositories/parent_portal_repository.dart';
import 'package:nalara/features/parent_portal/domain/entities/parent_portal.dart';
import 'package:nalara/features/parent_portal/presentation/pages/parent_shared_session_detail_page.dart';
import 'package:nalara/features/reschedule_requests/domain/entities/reschedule_request.dart';
import 'package:nalara/features/reschedule_requests/presentation/bloc/reschedule_submission_cubit.dart';
import 'package:nalara/features/reschedule_requests/presentation/pages/reschedule_requests_page.dart';
import 'package:nalara/features/reschedule_requests/presentation/widgets/reschedule_requests_grouped_list.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

class _Parent extends Fake implements ParentPortalRepository {
  bool pending = false;
  int writes = 0;
  final DateTime start = DateTime.now().toUtc().add(const Duration(days: 2));
  Completer<void>? gate;
  Object? failure;

  @override
  Future<SessionOverview> sessionOverview(String id) async => SessionOverview(
    lesson: Lesson(
      id: id,
      scheduleId: 'series',
      studentId: 'child',
      subjectId: 'math',
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      status: 'scheduled',
      attendance: 'pending',
      studentName: 'Robby',
      subjectName: 'Matematika',
    ),
    schedule: Schedule(
      id: 'series',
      studentId: 'child',
      subjectId: 'math',
      timezone: 'Asia/Jakarta',
      recurrence: 'none',
      status: 'scheduled',
      repeatCount: 1,
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
    ),
    reports: [],
    reschedulePending: pending,
  );

  @override
  Future<List<ParentRescheduleSlot>> availability(
    String sessionId,
    DateTime from,
    DateTime to,
  ) async => [
    ParentRescheduleSlot(
      startAt: start.add(const Duration(days: 1)),
      endAt: start.add(const Duration(days: 1, hours: 1)),
    ),
  ];

  @override
  Future<void> requestReschedule(
    String sessionId,
    DateTime startAt,
    DateTime endAt,
    String reason,
  ) async {
    writes++;
    if (gate != null) await gate!.future;
    if (failure != null) throw failure!;
    pending = true;
  }
}

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  tearDown(() async => getIt.reset());

  test(
    'submission locks after success and rejects double-send including the closing frame',
    () async {
      final cubit = RescheduleSubmissionCubit();
      final gate = Completer<void>();
      var writes = 0;
      final first = cubit.send(() async {
        writes++;
        await gate.future;
      }, () async => false);
      expect(
        await cubit.send(() async => writes++, () async => false),
        isFalse,
      );
      gate.complete();
      expect(await first, isTrue);
      expect(cubit.state.waiting, isTrue);
      expect(
        await cubit.send(() async => writes++, () async => false),
        isFalse,
      );
      expect(writes, 1);
      await cubit.close();
    },
  );

  test(
    'pending conflict and committed-but-lost response recover without another POST',
    () async {
      for (final typed in [true, false]) {
        final cubit = RescheduleSubmissionCubit();
        var recoveryReads = 0;
        expect(
          await cubit.send(
            () async => throw AppFailure(
              'response lost',
              code: typed ? 'RESCHEDULE_PENDING' : 'NETWORK',
            ),
            () async {
              recoveryReads++;
              return true;
            },
          ),
          isTrue,
        );
        expect(cubit.state.waiting, isTrue);
        expect(recoveryReads, typed ? 0 : 1);
        await cubit.close();
      }
    },
  );

  test(
    'unconfirmed failure remains retryable; late completion after disposal is ignored',
    () async {
      final cubit = RescheduleSubmissionCubit();
      expect(
        await cubit.send(
          () async => throw const AppFailure('offline'),
          () async => throw const AppFailure('offline'),
        ),
        isFalse,
      );
      expect(cubit.state.locked, isFalse);
      expect(cubit.state.error, 'offline');
      final gate = Completer<void>();
      final future = cubit.send(() => gate.future, () async => false);
      await cubit.close();
      gate.complete();
      expect(await future, isFalse);
    },
  );

  Future<void> render(WidgetTester tester, _Parent repository) async {
    getIt.registerSingleton<ParentPortalRepository>(repository);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ParentSharedSessionDetailPage(
          id: 'session',
          loadOverview: repository.sessionOverview,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'successful send closes the sheet, reloads pending status and disables a new request',
    (tester) async {
      final repository = _Parent()..gate = Completer<void>();
      await render(tester, repository);
      final action = find.byKey(const ValueKey('session-request-reschedule'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      final dropdown = tester.widget<NalaraDropdown<String>>(
        find.byKey(const ValueKey('parent-reschedule-slot')),
      );
      dropdown.onChanged!(dropdown.options.single.value);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('parent-reschedule-reason')),
        'Anak sakit',
      );
      final send = find.byKey(const ValueKey('parent-reschedule-send'));
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pump();
      expect(repository.writes, 1);
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(send, findsNothing);
      expect(tester.widget<SessionActionTile>(action).onPressed, isNull);
      expect(
        find.byKey(const ValueKey('session-view-reschedule-requests')),
        findsOneWidget,
      );
      repository.pending = false;
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(tester.widget<SessionActionTile>(action).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'reopening the session with a pending request never opens another form',
    (tester) async {
      final repository = _Parent()..pending = true;
      await render(tester, repository);
      final action = find.byKey(const ValueKey('session-request-reschedule'));
      expect(tester.widget<SessionActionTile>(action).onPressed, isNull);
      expect(
        find.byKey(const ValueKey('parent-reschedule-send')),
        findsNothing,
      );
      expect(repository.writes, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'preflight catches a request from another device before the sheet opens',
    (tester) async {
      final repository = _Parent();
      await render(tester, repository);
      repository.pending =
          true; // Page still contains the earlier false snapshot.
      final action = find.byKey(const ValueKey('session-request-reschedule'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('parent-reschedule-send')),
        findsNothing,
      );
      expect(tester.widget<SessionActionTile>(action).onPressed, isNull);
      expect(repository.writes, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'parent history is one grouped surface with a thin divider between requests',
    (tester) async {
      final start = DateTime.utc(2030, 1, 1, 8);
      final requests = [
        for (var i = 0; i < 2; i++)
          RescheduleRequest(
            id: 'r$i',
            sessionId: 's$i',
            studentId: 'c$i',
            studentName: 'Siswa $i',
            reason: 'Berhalangan',
            status: 'approved',
            oldStartAt: start,
            oldEndAt: start.add(const Duration(hours: 1)),
            requestedStartAt: start.add(const Duration(days: 1)),
            requestedEndAt: start.add(const Duration(days: 1, hours: 1)),
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: RescheduleRequestsPage(
            parent: true,
            timezone: 'Asia/Jakarta',
            loadRequests: (_) async =>
                PageResult(items: requests, total: 2, page: 1, limit: 5),
            onAction: (_, _) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RescheduleRequestsGroupedList), findsOneWidget);
      expect(
        find.byKey(const ValueKey('reschedule-divider-r0')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('reschedule-divider-r1')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
