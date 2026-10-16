import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nalara/features/students/domain/entities/student_summary.dart';
import 'package:nalara/features/students/presentation/widgets/student_progress_chart.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  Finder point(String date) =>
      find.byKey(ValueKey('student-progress-point-$date'));
  Finder label(String date) =>
      find.byKey(ValueKey('student-progress-date-$date'));
  final chart = find.byKey(const ValueKey('student-progress-chart'));
  Future<void> render(
    WidgetTester tester,
    List<StudentProgressPoint> points, {
    double width = 320,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Center(
              child: SizedBox(
                width: width,
                child: StudentProgressChart(points: points),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void aligned(WidgetTester tester, String date) {
    expect(
      tester.getCenter(label(date)).dx,
      closeTo(tester.getCenter(point(date)).dx, .01),
    );
  }

  testWidgets(
    'one real point and its date are both centered, without fabricated neighbors',
    (tester) async {
      await render(tester, const [
        StudentProgressPoint(date: '2026-10-15', progress: 50),
      ]);
      aligned(tester, '2026-10-15');
      expect(
        tester.getCenter(point('2026-10-15')).dx,
        closeTo(tester.getCenter(chart).dx, .01),
      );
      expect(find.text('15 Okt'), findsOneWidget);
      expect(find.text('14 Okt'), findsNothing);
    },
  );

  testWidgets(
    'six samples keep the middle date at its actual 60 percent position, not centered',
    (tester) async {
      await render(
        tester,
        List.generate(
          6,
          (index) => StudentProgressPoint(
            date: '2026-10-${10 + index}',
            progress: index * 20,
          ),
        ),
      );
      for (final date in ['2026-10-10', '2026-10-13', '2026-10-15']) {
        aligned(tester, date);
      }
      final start = tester.getCenter(point('2026-10-10')).dx;
      final end = tester.getCenter(point('2026-10-15')).dx;
      expect(
        tester.getCenter(label('2026-10-13')).dx,
        closeTo(start + (end - start) * .6, .01),
      );
    },
  );

  testWidgets(
    'irregular calendar dates and month boundaries use elapsed days, not array indices',
    (tester) async {
      await render(tester, const [
        StudentProgressPoint(date: '2026-10-30', progress: 0),
        StudentProgressPoint(date: '2026-10-31', progress: 50),
        StudentProgressPoint(date: '2026-11-04', progress: 100),
      ]);
      final start = tester.getCenter(point('2026-10-30')).dx;
      final end = tester.getCenter(point('2026-11-04')).dx;
      expect(
        tester.getCenter(point('2026-10-31')).dx,
        closeTo(start + (end - start) / 5, .01),
      );
      for (final date in ['2026-10-30', '2026-10-31', '2026-11-04']) {
        if (label(date).evaluate().isNotEmpty) aligned(tester, date);
      }
    },
  );

  testWidgets(
    'narrow/large-text dates stay aligned and inside the card without overlapping',
    (tester) async {
      await render(
        tester,
        List.generate(
          7,
          (index) =>
              StudentProgressPoint(date: '2026-10-${10 + index}', progress: 50),
        ),
        width: 150,
        scale: 2,
      );
      final bounds = tester.getRect(chart);
      final labels = <Rect>[];
      for (var index = 0; index < 7; index++) {
        final date = '2026-10-${10 + index}';
        if (label(date).evaluate().isEmpty) continue;
        aligned(tester, date);
        final rect = tester.getRect(label(date));
        expect(rect.left, greaterThanOrEqualTo(bounds.left));
        expect(rect.right, lessThanOrEqualTo(bounds.right));
        labels.add(rect);
      }
      for (var index = 1; index < labels.length; index++) {
        expect(
          labels[index].left,
          greaterThanOrEqualTo(labels[index - 1].right),
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty history never draws a chart or date label', (
    tester,
  ) async {
    await render(tester, const []);
    expect(chart, findsNothing);
    expect(
      find.descendant(
        of: find.byType(StudentProgressChart),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });
}
