import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/entities/lesson_timing.dart';
import 'package:nalara/features/schedules/presentation/widgets/lesson_clock.dart';
import 'package:nalara/features/schedules/presentation/widgets/lesson_status.dart';
import 'package:nalara/features/schedules/presentation/widgets/lesson_timeline_card.dart';
import 'package:nalara/features/schedules/presentation/widgets/session_action_cards.dart';
import 'package:nalara/features/schedules/presentation/widgets/group_attendance_card.dart';
import 'package:nalara/features/dashboard/presentation/widgets/home_lesson_card.dart';
import 'package:nalara/utils/color.dart';

final start = DateTime.utc(2026, 10, 21, 8);
Lesson lesson({String status = 'scheduled', String attendance = 'pending'}) =>
    Lesson(
      id: 'one',
      scheduleId: 'series',
      studentId: 'child',
      subjectId: 'subject',
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      status: status,
      attendance: attendance,
      subjectName: 'Matematika',
      studentName: 'Robby',
    );

void main() {
  setUpAll(tz.initializeTimeZones);
  test('time phases honor exact start/end and never fabricate completion', () {
    final cases = <(DateTime, LessonPhase)>[
      (start.subtract(const Duration(days: 1)), LessonPhase.upcoming),
      (start.subtract(const Duration(minutes: 16)), LessonPhase.upcoming),
      (start.subtract(const Duration(minutes: 15)), LessonPhase.soon),
      (start.subtract(const Duration(seconds: 1)), LessonPhase.soon),
      (start, LessonPhase.ongoing),
      (start.add(const Duration(minutes: 49)), LessonPhase.ongoing),
      (start.add(const Duration(minutes: 50)), LessonPhase.ending),
      (start.add(const Duration(minutes: 59, seconds: 59)), LessonPhase.ending),
      (start.add(const Duration(hours: 1)), LessonPhase.elapsed),
    ];
    for (final (now, phase) in cases) {
      expect(LessonTiming.at(lesson(), now).phase, phase);
    }
    expect(
      LessonTiming.at(lesson(status: 'cancelled'), start).phase,
      LessonPhase.cancelled,
    );
    expect(
      LessonTiming.at(
        lesson(status: 'completed', attendance: 'present'),
        start,
      ).phase,
      LessonPhase.ongoing,
    );
    expect(
      LessonTiming.at(
        lesson(status: 'completed', attendance: 'present'),
        start.add(const Duration(hours: 1)),
      ).phase,
      LessonPhase.completed,
    );
    expect(
      LessonTiming.at(
        lesson(),
        start.subtract(const Duration(seconds: 1)),
      ).label,
      'Mulai 1 menit lagi',
    );
    expect(
      LessonTiming.attendanceAvailable(
        lesson(),
        start.subtract(const Duration(milliseconds: 1)),
      ),
      isFalse,
    );
    expect(LessonTiming.attendanceAvailable(lesson(), start), isTrue);
    expect(LessonTiming.attendanceAvailable(lesson(), start.toLocal()), isTrue);
  });

  Future<void> render(
    WidgetTester tester,
    Widget child, {
    DateTime? now,
    bool reduce = false,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduce,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: LessonClockScope(now: () => now ?? start, child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'future neutral card remains tappable; Home uses the same compact component',
    (tester) async {
      var taps = 0;
      await render(
        tester,
        HomeLessonCard(
          lesson: lesson(),
          timezone: 'Asia/Jakarta',
          onTap: () => taps++,
        ),
        now: start.subtract(const Duration(days: 1)),
      );
      expect(find.text('Belum dimulai'), findsOneWidget);
      expect(
        tester
            .widget<LessonTimelineCard>(find.byType(LessonTimelineCard))
            .compact,
        isTrue,
      );
      await tester.tap(find.text('Matematika'));
      expect(taps, 1);
      final surfaces = tester.widgetList<Material>(find.byType(Material));
      expect(surfaces.any((m) => m.color == NalaraColors.surface), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'active card has green emphasis; only its marker fades and reduced motion is respected',
    (tester) async {
      await render(
        tester,
        LessonTimelineCard(
          lesson: lesson(),
          timezone: 'Asia/Jakarta',
          onTap: () {},
        ),
      );
      expect(
        find.text('Berlangsung sesuai jadwal · sisa 60 menit'),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<Material>(find.byType(Material))
            .any((m) => m.color == NalaraColors.sessionActiveSurface),
        isTrue,
      );
      final fadeFinder = find.descendant(
        of: find.byType(LessonStatusDot),
        matching: find.byType(FadeTransition),
      );
      final opacity = tester.widget<FadeTransition>(fadeFinder).opacity.value;
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        tester.widget<FadeTransition>(fadeFinder).opacity.value,
        isNot(opacity),
      );
      await render(
        tester,
        LessonTimelineCard(
          lesson: lesson(),
          timezone: 'Asia/Jakarta',
          onTap: () {},
        ),
        reduce: true,
      );
      expect(tester.widget<FadeTransition>(fadeFinder).opacity.value, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'single and group future forms explain why attendance is disabled',
    (tester) async {
      const reason = 'Presensi tersedia saat sesi dimulai.';
      await render(
        tester,
        const Column(
          children: [
            SessionAttendanceCard(
              attendance: 'pending',
              busy: false,
              onSave: null,
              unavailableReason: reason,
            ),
            GroupAttendanceCard(
              participants: [
                SessionParticipant(
                  sessionId: 'one',
                  studentId: 'child',
                  studentName: 'Robby',
                  attendance: 'pending',
                  status: 'scheduled',
                ),
              ],
              busy: false,
              onSave: null,
              unavailableReason: reason,
            ),
          ],
        ),
      );
      expect(find.text(reason), findsNWidgets(2));
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('session-save-attendance')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('group-all-present')))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('clock is minute aligned and stops when deactivated or disposed', () {
    fakeAsync((async) {
      var current = start.add(const Duration(seconds: 30));
      final clock = LessonClockCubit(now: () => current);
      final emissions = <DateTime>[];
      final subscription = clock.stream.listen(emissions.add);
      clock.setActive(true);
      async.flushMicrotasks();
      expect(clock.running, isTrue);
      expect(emissions, [start.add(const Duration(seconds: 30))]);
      current = start.add(const Duration(minutes: 1));
      async.elapse(const Duration(seconds: 29));
      async.flushMicrotasks();
      expect(emissions.length, 1);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(emissions, [start.add(const Duration(seconds: 30)), current]);
      clock.setActive(false);
      expect(clock.running, isFalse);
      current = start.add(const Duration(minutes: 2));
      async.elapse(const Duration(minutes: 1));
      async.flushMicrotasks();
      expect(emissions.length, 2);
      subscription.cancel();
      clock.close();
      expect(clock.running, isFalse);
    });
  });

  testWidgets(
    'page clock pauses in background and offstage, then catches up on return',
    (tester) async {
      var current = start;
      Future<void> mount(bool enabled) => tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: enabled,
            child: LessonClockScope(
              now: () => current,
              child: LessonClockBuilder(
                builder: (_, now) => Text(now.toIso8601String()),
              ),
            ),
          ),
        ),
      );
      await mount(true);
      expect(find.text(current.toIso8601String()), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      current = start.add(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 2));
      expect(find.text(start.toIso8601String()), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text(current.toIso8601String()), findsOneWidget);
      await mount(false);
      final pausedAt = current;
      current = current.add(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 2));
      expect(find.text(pausedAt.toIso8601String()), findsOneWidget);
      await mount(true);
      await tester.pump();
      expect(find.text(current.toIso8601String()), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'narrow layout and larger text retain full status without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await render(
        tester,
        LessonTimelineCard(
          lesson: lesson(),
          timezone: 'Asia/Jakarta',
          onTap: () {},
        ),
        reduce: true,
        scale: 1.8,
      );
      expect(find.text('Matematika'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
