import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/shared/widgets/nalara_progress_bar.dart';

void main() {
  Future<void> render(
    WidgetTester tester, {
    int? progress,
    TextDirection direction = TextDirection.ltr,
    Color? accent,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Directionality(
              textDirection: direction,
              child: SizedBox(
                width: 200,
                child: NalaraProgressBar(
                  progress: progress,
                  semanticsLabel: 'Progres minggu ini',
                  emptyLabel: 'Belum ada target minggu ini',
                  fillColor: Colors.green,
                  backgroundColor: const Color(0xFFE7EFEA),
                  accentColor: accent,
                  height: 6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'plain progress has rounded fill, no decorative segment and exact server percentage',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await render(tester, progress: 30);
      final fill = find.byKey(const ValueKey('nalara-progress-fill'));
      expect(tester.getSize(fill), const Size(60, 6));
      final decoration =
          tester.widget<DecoratedBox>(fill).decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(3));
      expect(
        find.byKey(const ValueKey('nalara-progress-accent')),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Progres minggu ini'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'null and zero stay distinct, full progress fills the track, and out-of-range values clamp',
    (tester) async {
      for (final value in [null, 0, -5]) {
        await render(tester, progress: value);
        expect(
          find.byKey(const ValueKey('nalara-progress-fill')),
          findsNothing,
        );
        final semantics = tester.widget<Semantics>(
          find
              .descendant(
                of: find.byType(NalaraProgressBar),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(
          semantics.properties.label,
          value == null ? 'Belum ada target minggu ini' : 'Progres minggu ini',
        );
        expect(semantics.properties.value, value == null ? null : '0 persen');
      }
      for (final value in [100, 120]) {
        await render(tester, progress: value);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('nalara-progress-fill')))
              .width,
          200,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fill follows RTL and optional decorative accent remains available to other callers',
    (tester) async {
      await render(tester, progress: 30, direction: TextDirection.rtl);
      final bar = tester.getRect(find.byType(NalaraProgressBar));
      final fill = tester.getRect(
        find.byKey(const ValueKey('nalara-progress-fill')),
      );
      expect(fill.right, bar.right);
      await render(tester, progress: 30, accent: Colors.orange);
      expect(
        find.byKey(const ValueKey('nalara-progress-accent')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('nalara-progress-fill')))
            .width,
        60,
      );
      await render(tester, progress: 100, accent: Colors.orange);
      expect(
        find.byKey(const ValueKey('nalara-progress-accent')),
        findsNothing,
      );
    },
  );
}
