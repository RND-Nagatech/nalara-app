import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/shared/widgets/nalara_dropdown.dart';
import 'package:nalara/utils/app_theme.dart';

List<NalaraDropdownOption<int>> choices([int count = 9]) => List.generate(
  count,
  (index) => NalaraDropdownOption(value: index, label: 'Pilihan ${index + 1}'),
);

void main() {
  Finder field() => find.byType(NalaraDropdown<int>);
  Finder panel() => find.byKey(const ValueKey('nalara-dropdown-panel'));
  Finder search() => find.byKey(const ValueKey('nalara-dropdown-search'));
  Finder list() => find.byKey(const ValueKey('nalara-dropdown-options'));
  Finder row(int value) => find.byKey(ValueKey(value));
  void viewport(WidgetTester tester, [Size size = const Size(430, 900)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(
    WidgetTester tester,
    Widget child, {
    double scale = 1,
    double keyboard = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 24, bottom: 20),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SafeArea(
            child: Padding(padding: const EdgeInsets.all(20), child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(field());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'custom branded panel exposes four rows, scrolls all options and returns stable IDs',
    (tester) async {
      viewport(tester);
      final selected = <int?>[];
      await render(
        tester,
        NalaraDropdown<int>(
          options: choices(),
          onChanged: selected.add,
          decoration: const InputDecoration(labelText: 'Pilih siswa'),
        ),
      );
      await open(tester);
      expect(panel(), findsOneWidget);
      expect(search(), findsOneWidget);
      expect(
        tester.getSize(list()).height,
        52 * NalaraDropdown.maxVisibleOptions,
      );
      for (var index = 0; index < 4; index++) {
        expect(row(index).hitTestable(), findsOneWidget);
      }
      expect(row(4).hitTestable(), findsNothing);
      expect(
        tester.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility,
        isTrue,
      );
      await tester.scrollUntilVisible(
        row(7),
        100,
        scrollable: find
            .descendant(of: list(), matching: find.byType(Scrollable))
            .first,
      );
      await tester.tap(row(7));
      await tester.pumpAndSettle();
      expect(panel(), findsNothing);
      expect(selected, [7]);
      expect(find.text('Pilihan 8'), findsOneWidget);
      await open(tester);
      await tester.enterText(search(), 'Pilihan 8');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(tester.getSize(list()).height, 52);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'case-insensitive multi-word search includes aliases, clear and no-results',
    (tester) async {
      viewport(tester);
      final options = [
        const NalaraDropdownOption(
          value: 1,
          label: 'Ibu Sari',
          searchText: '081234',
        ),
        const NalaraDropdownOption(
          value: 2,
          label: 'Ibu Nara',
          searchText: '089999',
        ),
      ];
      final changes = <int?>[];
      await render(
        tester,
        NalaraDropdown<int>(options: options, value: 2, onChanged: changes.add),
      );
      await open(tester);
      await tester.enterText(search(), '  SARI    0812  ');
      await tester.pumpAndSettle();
      expect(row(1), findsOneWidget);
      expect(row(2), findsNothing);
      expect(changes, isEmpty);
      expect(options.length, 2);
      await tester.enterText(search(), 'tidak cocok');
      await tester.pumpAndSettle();
      expect(
        find.text('Tidak ada pilihan yang sesuai pencarian.'),
        findsOneWidget,
      );
      expect(list(), findsNothing);
      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pumpAndSettle();
      expect(row(1), findsOneWidget);
      expect(row(2), findsOneWidget);
      await tester.tap(find.byTooltip('Tutup pilihan'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(find.text('Ibu Nara'), findsOneWidget);
      await open(tester);
      expect(tester.widget<TextField>(search()).controller!.text, isEmpty);
    },
  );

  testWidgets(
    'Form validate, save and reset use the selected ID without requiring parent rebuild',
    (tester) async {
      viewport(tester);
      final form = GlobalKey<FormState>();
      final changes = <int?>[];
      int? saved;
      await render(
        tester,
        Form(
          key: form,
          child: NalaraDropdown<int>(
            options: choices(3),
            onChanged: changes.add,
            validator: (value) =>
                value == null ? 'Pilih siswa terlebih dahulu' : null,
            onSaved: (value) => saved = value,
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Pilih siswa terlebih dahulu'), findsOneWidget);
      await open(tester);
      await tester.tap(row(2));
      await tester.pumpAndSettle();
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect(saved, 2);
      form.currentState!.reset();
      await tester.pumpAndSettle();
      expect(changes, [2, null]);
      expect(tester.state<FormFieldState<int>>(field()).value, isNull);
    },
  );

  testWidgets(
    'controlled values synchronize; missing options never auto-clear a stored selection',
    (tester) async {
      viewport(tester);
      var selected = 0;
      var options = choices(3);
      late StateSetter update;
      final changes = <int?>[];
      await render(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return NalaraDropdown<int>(
              value: selected,
              options: options,
              onChanged: changes.add,
            );
          },
        ),
      );
      update(() => selected = 2);
      await tester.pumpAndSettle();
      expect(find.text('Pilihan 3'), findsOneWidget);
      expect(changes, isEmpty);
      update(() => options = choices(1));
      await tester.pumpAndSettle();
      expect(find.text('Pilihan tersimpan'), findsOneWidget);
      expect(tester.state<FormFieldState<int>>(field()).value, 2);
      expect(changes, isEmpty);
    },
  );

  testWidgets(
    'disabled field/option and cancelling cannot change the selected value',
    (tester) async {
      viewport(tester);
      final changes = <int?>[];
      var enabled = false;
      late StateSetter update;
      await render(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return NalaraDropdown<int>(
              enabled: enabled,
              onChanged: changes.add,
              value: 2,
              options: const [
                NalaraDropdownOption(
                  value: 1,
                  label: 'Tidak tersedia',
                  enabled: false,
                ),
                NalaraDropdownOption(value: 2, label: 'Dipilih'),
              ],
            );
          },
        ),
      );
      await open(tester);
      expect(panel(), findsNothing);
      update(() => enabled = true);
      await tester.pumpAndSettle();
      await open(tester);
      expect(tester.widget<InkWell>(row(1)).onTap, isNull);
      await tester.tap(find.byTooltip('Tutup pilihan'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(find.text('Dipilih'), findsOneWidget);
    },
  );

  testWidgets(
    'late selections after external value change or disabling are ignored',
    (tester) async {
      viewport(tester);
      var selected = 0;
      var enabled = true;
      final changes = <int?>[];
      late StateSetter update;
      await render(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return NalaraDropdown<int>(
              value: selected,
              options: choices(3),
              enabled: enabled,
              onChanged: changes.add,
            );
          },
        ),
      );
      await open(tester);
      update(() => selected = 2);
      await tester.pumpAndSettle();
      await tester.tap(row(1));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(find.text('Pilihan 3'), findsOneWidget);
      await open(tester);
      update(() => enabled = false);
      await tester.pumpAndSettle();
      await tester.tap(row(1));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
    },
  );

  testWidgets(
    'empty source is distinct from search-empty and Escape cancels the panel',
    (tester) async {
      viewport(tester);
      final changes = <int?>[];
      await render(
        tester,
        NalaraDropdown<int>(options: const [], onChanged: changes.add),
      );
      await open(tester);
      expect(find.text('Belum ada pilihan tersedia.'), findsOneWidget);
      expect(
        find.text('Tidak ada pilihan yang sesuai pencarian.'),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(panel(), findsNothing);
      expect(changes, isEmpty);
    },
  );

  testWidgets(
    'large text, 320px and keyboard keep search/options inside available space',
    (tester) async {
      viewport(tester, const Size(320, 568));
      await render(
        tester,
        NalaraDropdown<int>(
          options: [
            for (var index = 0; index < 10; index++)
              NalaraDropdownOption(
                value: index,
                label: 'Nama Orang Tua yang cukup panjang $index',
              ),
          ],
          onChanged: (_) {},
          decoration: const InputDecoration(labelText: 'Orang Tua / keluarga'),
        ),
        scale: 2,
        keyboard: 200,
      );
      await open(tester);
      expect(panel(), findsOneWidget);
      expect(
        tester.getSize(list()).height,
        lessThanOrEqualTo((28 * 2.8 + 12) * 4),
      );
      await tester.enterText(search(), 'panjang 9');
      await tester.pumpAndSettle();
      expect(row(9).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'disposing the field/panel during selection cannot notify a removed widget',
    (tester) async {
      viewport(tester);
      final changes = <int?>[];
      await render(
        tester,
        NalaraDropdown<int>(options: choices(), onChanged: changes.add),
      );
      await open(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
