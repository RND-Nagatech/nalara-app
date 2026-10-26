import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/entities/lesson_timeline_segment.dart';
import 'package:nalara/features/schedules/domain/entities/lesson_timing.dart';
import 'package:nalara/features/schedules/presentation/widgets/lesson_clock.dart';
import 'package:nalara/features/schedules/presentation/widgets/lesson_status.dart';
import 'package:nalara/features/schedules/presentation/widgets/lesson_timeline_card.dart';
import 'package:nalara/features/schedules/presentation/widgets/lesson_timeline_connector.dart';
import 'package:nalara/features/dashboard/presentation/widgets/home_lesson_card.dart';
import 'package:nalara/utils/color.dart';

final start = DateTime.utc(2026, 10, 21, 8);
Lesson item(String id, DateTime at, {String status = 'scheduled'}) => Lesson(
  id: id,
  scheduleId: id,
  studentId: 'child',
  subjectId: 'math',
  startAt: at,
  endAt: at.add(const Duration(minutes: 45)),
  status: status,
  attendance: 'pending',
  studentName: 'Siswa',
  subjectName: 'Matematika',
);

void main() {
  setUpAll(tz.initializeTimeZones);
  test(
    'rail follows actual time between starts, including a gap, without changing attendance',
    () {
      final first = item('a', start);
      final next = item('b', start.add(const Duration(hours: 2)));
      final segment = LessonTimelineSegment.between(first, next)!;
      expect(segment.progressAt(start.subtract(const Duration(hours: 1))), 0);
      expect(segment.progressAt(start), 0);
      expect(segment.progressAt(start.add(const Duration(hours: 1))), .5);
      expect(segment.progressAt(next.startAt), 1);
      expect(segment.progressAt(next.startAt.add(const Duration(hours: 1))), 1);
      expect(segment.movingAt(next.startAt), isFalse);
      expect(segment.remainingAt(next.startAt), Duration.zero);
      expect(first.attendance, 'pending');
      expect(
        LessonTiming.at(first, start.add(const Duration(hours: 1))).phase,
        LessonPhase.elapsed,
      );
    },
  );

  test(
    'last, simultaneous, backwards or cancelled neighbors do not create false rail intervals',
    () {
      final first = item('a', start);
      for (final next in <Lesson?>[
        null,
        item('same', start),
        item('old', start.subtract(const Duration(minutes: 1))),
        item(
          'cancelled',
          start.add(const Duration(hours: 1)),
          status: 'cancelled',
        ),
      ]) {
        expect(LessonTimelineSegment.between(first, next), isNull);
      }
      expect(
        LessonTimelineSegment.between(
          item('cancelled', start, status: 'cancelled'),
          item('b', start.add(const Duration(hours: 1))),
        ),
        isNull,
      );
      expect(
        LessonTimelineSegment(from: start, until: start).progressAt(start),
        0,
      );
    },
  );

  Future<void> rail(
    WidgetTester tester, {
    required DateTime now,
    bool enabled = true,
    bool reduced = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: enabled,
            child: Center(
              child: SizedBox(
                width: 2,
                height: 200,
                child: LessonTimelineConnector(
                  segment: LessonTimelineSegment(
                    from: start,
                    until: start.add(const Duration(hours: 1)),
                  ),
                  now: now,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  LessonTimelineRailPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find
                    .descendant(
                      of: find.byType(LessonTimelineConnector),
                      matching: find.byType(CustomPaint),
                    )
                    .first,
              )
              .painter!
          as LessonTimelineRailPainter;

  testWidgets(
    'only the rail paint advances linearly, clamps at next start, and handles offstage/reduced motion',
    (tester) async {
      await rail(tester, now: start);
      expect(painter(tester).progress.value, 0);
      await tester.pump(const Duration(minutes: 30));
      expect(painter(tester).progress.value, closeTo(.5, .001));
      await rail(
        tester,
        now: start.add(const Duration(minutes: 30)),
        enabled: false,
      );
      await tester.pump(const Duration(minutes: 10));
      expect(painter(tester).progress.value, .5);
      await rail(tester, now: start.add(const Duration(minutes: 40)));
      expect(painter(tester).progress.value, closeTo(2 / 3, .001));
      await rail(
        tester,
        now: start.add(const Duration(minutes: 45)),
        reduced: true,
      );
      await tester.pump(const Duration(minutes: 5));
      expect(painter(tester).progress.value, .75);
      await rail(tester, now: start.add(const Duration(hours: 1)));
      expect(painter(tester).progress.value, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'active marker has a pulsing core; passed and upcoming markers are hollow',
    (tester) async {
      for (final phase in [
        LessonPhase.ongoing,
        LessonPhase.elapsed,
        LessonPhase.completed,
        LessonPhase.upcoming,
        LessonPhase.cancelled,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: LessonStatusDot(timing: LessonTiming(phase, 'Status')),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('lesson-timeline-marker-core')),
          phase == LessonPhase.ongoing ? findsOneWidget : findsNothing,
        );
        final ring = tester.widget<Container>(
          find.byKey(const ValueKey('lesson-timeline-marker-ring')),
        );
        expect((ring.decoration! as BoxDecoration).color, isNull);
        if (phase == LessonPhase.elapsed || phase == LessonPhase.completed) {
          expect(
            ((ring.decoration! as BoxDecoration).border! as Border).top.color,
            NalaraColors.green,
          );
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Home connects previews, aligns rails and markers, and leaves the last row without an outgoing line',
    (tester) async {
      final lessons = [
        for (var i = 0; i < 3; i++) item('$i', start.add(Duration(hours: i))),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LessonClockScope(
                now: () => start.add(const Duration(minutes: 30)),
                child: Column(
                  children: [
                    for (var i = 0; i < lessons.length; i++)
                      HomeLessonCard(
                        lesson: lessons[i],
                        nextLesson: i + 1 < lessons.length
                            ? lessons[i + 1]
                            : null,
                        timezone: 'Asia/Jakarta',
                        onTap: () {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LessonTimelineConnector), findsNWidgets(2));
      final line = tester.getRect(find.byType(LessonTimelineConnector).first);
      final marker = tester.getRect(find.byType(LessonStatusDot).first);
      final nextMarker = tester.getRect(find.byType(LessonStatusDot).at(1));
      expect(line.center.dx, closeTo(marker.center.dx, .01));
      expect(line.top, greaterThan(marker.bottom));
      expect(line.bottom, lessThan(nextMarker.top));
      expect(painter(tester).progress.value, .5);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('day boundaries use display timezone, not UTC dates', (
    tester,
  ) async {
    Future<void> show(DateTime a, DateTime b) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonClockScope(
            now: () => a,
            child: LessonTimelineCard(
              lesson: item('a', a),
              nextLesson: item('b', b),
              timezone: 'Asia/Jakarta',
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await show(DateTime.utc(2026, 10, 21, 15), DateTime.utc(2026, 10, 21, 18));
    expect(find.byType(LessonTimelineConnector), findsNothing);
    await show(DateTime.utc(2026, 10, 21, 18), DateTime.utc(2026, 10, 22, 2));
    expect(find.byType(LessonTimelineConnector), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
