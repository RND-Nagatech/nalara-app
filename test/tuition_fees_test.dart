import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/tuition_fees/data/tuition_model.dart';
import 'package:nalara/features/tuition_fees/domain/tuition_fee.dart';
import 'package:nalara/features/tuition_fees/presentation/tuition_fee_section.dart';
import 'package:nalara/utils/app_theme.dart';
import 'tuition_fixtures.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  test(
    'WhatsApp uses the real teacher phone, escaped child name and local greeting',
    () {
      final uri = tuitionContactUri(
        '081234567890',
        'Alya & Budi',
        DateTime(2031, 1, 1, 12),
      );
      expect(uri!.host, 'wa.me');
      expect(uri.path, '/6281234567890');
      expect(uri.queryParameters['text'], contains('selamat siang'));
      expect(
        uri.queryParameters['text'],
        contains('orang tua dari Alya & Budi'),
      );
      for (final invalid in [
        null,
        '',
        '123',
        'javascript:bad',
        'https://example.com',
      ]) {
        expect(tuitionContactUri(invalid, 'Anak', DateTime.now()), isNull);
      }
      expect(
        tuitionContactUri(
          '+6281234567890',
          'A',
          DateTime(2031, 1, 1, 19),
        )!.queryParameters['text'],
        contains('selamat malam'),
      );
    },
  );
  test(
    'fee model keeps date-only and integer rupiah, not a fabricated payment status',
    () {
      final overview = TuitionModel({
        'fee': {
          '_id': 'fee',
          'studentId': 'child',
          'amount': 250000,
          'dueDate': '2031-01-01',
          'status': 'unpaid',
          'version': 2,
        },
        'teacher': {'name': 'Guru', 'phone': null, 'timezone': 'Asia/Jakarta'},
        'automaticReminders': false,
      }).toEntity();
      expect(overview.fee!.dueDate, '2031-01-01');
      expect(overview.fee!.amount, 250000);
      expect(overview.fee!.paid, isFalse);
      expect(overview.teacherPhone, isNull);
      expect(overview.automaticReminders, isFalse);
    },
  );
  Future<void> render(
    WidgetTester tester,
    TuitionFake repository, {
    required bool parent,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TuitionFeeSection(
              studentId: 'child',
              studentName: 'Alya',
              reader: repository,
              readOnly: parent,
              active: true,
              refreshToken: repository,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'parent sees exact fee/deadline, contact action and no academic/payment editing',
    (tester) async {
      final repository = TuitionFake();
      await repository.save(
        'child',
        amount: 250000,
        dueDate: '2031-01-01',
        status: 'unpaid',
        version: 0,
      );
      await render(tester, repository, parent: true);
      expect(find.text('Rp 250.000'), findsOneWidget);
      expect(find.text('1 Januari 2031'), findsOneWidget);
      expect(find.text('Hubungi guru'), findsOneWidget);
      expect(find.text('Tandai lunas'), findsNothing);
      expect(find.text('Edit biaya bimbel'), findsNothing);
      expect(repository.reads, ['child']);
      expect(repository.saves, 1);
    },
  );
  testWidgets(
    'teacher can configure missing fees, while parent empty state stays read-only',
    (tester) async {
      final repository = TuitionFake();
      await render(tester, repository, parent: false);
      expect(find.text('Atur biaya bimbel'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await render(tester, repository, parent: true);
      expect(find.text('Atur biaya bimbel'), findsNothing);
      expect(find.text('Belum ada biaya bimbel'), findsOneWidget);
      expect(find.text('Hubungi guru'), findsOneWidget);
      expect(repository.saves, 0);
    },
  );
  testWidgets(
    'missing teacher number disables WhatsApp without guessing a destination',
    (tester) async {
      final repository = TuitionFake()
        ..value = const TuitionOverview(
          fee: null,
          teacherName: 'Guru',
          teacherPhone: null,
          timezone: 'Asia/Jakarta',
          automaticReminders: true,
        );
      await render(tester, repository, parent: true);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Hubungi guru'),
      );
      expect(button.onPressed, isNull);
      expect(repository.saves, 0);
    },
  );
}
