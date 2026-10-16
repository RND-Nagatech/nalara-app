import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/shared/widgets/nalara_load_more.dart';
import 'package:nalara/utils/app_theme.dart';

void main() {
  Future<void> render(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hides itself when the list has no next batch', (tester) async {
    await render(
      tester,
      NalaraLoadMoreButton(hasMore: false, loading: false, onPressed: () {}),
    );

    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Muat lebih banyak'), findsNothing);
  });

  testWidgets('exposes a themed action and forwards its callback', (
    tester,
  ) async {
    var presses = 0;
    await render(
      tester,
      NalaraLoadMoreButton(
        hasMore: true,
        loading: false,
        onPressed: () => presses++,
        buttonKey: const ValueKey('load-more'),
      ),
    );

    expect(find.byKey(const ValueKey('load-more')), findsOneWidget);
    expect(find.text('Muat lebih banyak'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('load-more')));
    expect(presses, 1);
  });

  testWidgets('disables the action and shows progress while loading', (
    tester,
  ) async {
    await render(
      tester,
      NalaraLoadMoreButton(hasMore: true, loading: true, onPressed: () {}),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
