import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/shared/widgets/nalara_header.dart';
import 'package:nalara/shared/widgets/nalara_page_header.dart';
import 'package:nalara/utils/color.dart';

void main() {
  for (final spacing in [0.0, 14.0, 28.0]) {
    testWidgets('divider is the header bottom edge at spacing $spacing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NalaraPageLayout(
              bottomSpacing: spacing,
              header: const SizedBox(
                key: ValueKey('header-content'),
                height: 72,
              ),
              body: ListView(
                key: const ValueKey('body-viewport'),
                padding: EdgeInsets.zero,
                children: const [SizedBox(height: 2000)],
              ),
            ),
          ),
        ),
      );
      final header = tester.getRect(find.byType(NalaraHeader));
      final content = tester.getRect(
        find.byKey(const ValueKey('header-content')),
      );
      final divider = tester.getRect(find.byType(Divider));
      final viewport = tester.getRect(
        find.byKey(const ValueKey('body-viewport')),
      );
      expect(divider.top - content.bottom, closeTo(spacing, .01));
      expect(divider.height, 1);
      expect(divider.bottom, closeTo(header.bottom, .01));
      expect(viewport.top, closeTo(divider.bottom, .01));
      await tester.drag(
        find.byKey(const ValueKey('body-viewport')),
        const Offset(0, -160),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(Divider)), divider);
      expect(
        tester.getRect(find.byKey(const ValueKey('body-viewport'))).top,
        closeTo(divider.bottom, .01),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('header inherits the current page color without adding a band', (
    tester,
  ) async {
    const pageColor = Color(0xFFFBF8F0);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(scaffoldBackgroundColor: NalaraColors.cream),
        home: const Scaffold(
          backgroundColor: pageColor,
          body: NalaraPageLayout(
            header: SizedBox(height: 60),
            body: SizedBox.expand(key: ValueKey('body')),
          ),
        ),
      ),
    );
    final surface = find.descendant(
      of: find.byType(NalaraHeader),
      matching: find.byType(ColoredBox),
    );
    expect(tester.widget<ColoredBox>(surface).color, pageColor);
    expect(
      tester.widget<Divider>(find.byType(Divider)).color,
      NalaraColors.headerDivider,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('body'))).top,
      closeTo(tester.getRect(find.byType(Divider)).bottom, .01),
    );
  });

  testWidgets('hidden divider preserves header-to-pinned-tab spacing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NalaraPageLayout(
            showDivider: false,
            header: SizedBox(key: ValueKey('header-content'), height: 60),
            body: SizedBox.expand(key: ValueKey('tabs-body')),
          ),
        ),
      ),
    );
    expect(find.byType(Divider), findsNothing);
    expect(
      tester.getRect(find.byKey(const ValueKey('tabs-body'))).top -
          tester.getRect(find.byKey(const ValueKey('header-content'))).bottom,
      closeTo(14, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('standard page scaffold keeps the safe area above the divider', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(top: 28, bottom: 20)),
          child: child!,
        ),
        home: NalaraPageScaffold(
          title: 'Pengaturan',
          onBack: () {},
          body: ListView(
            key: const ValueKey('standard-body'),
            padding: EdgeInsets.zero,
            children: const [SizedBox(height: 2000)],
          ),
        ),
      ),
    );
    expect(
      tester.getRect(find.text('Pengaturan')).top,
      greaterThanOrEqualTo(28),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('standard-body'))).top,
      closeTo(tester.getRect(find.byType(Divider)).bottom, .01),
    );
    expect(tester.takeException(), isNull);
  });
}
