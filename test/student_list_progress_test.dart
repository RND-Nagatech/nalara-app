import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/students/data/models/student_model.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/presentation/widgets/student_list_card.dart';
import 'package:nalara/features/students/presentation/widgets/student_list_progress_bar.dart';
import 'package:nalara/features/students/presentation/widgets/students_style.dart';
import 'package:nalara/shared/widgets/nalara_progress_bar.dart';
import 'package:nalara/utils/app_theme.dart';

Map<String, dynamic> record({int? progress = 53, int count = 3}) => {
  '_id': 's1',
  'name': 'Andi Saputra',
  'grade': 'Kelas 6',
  'status': 'active',
  'learningSummary': {
    'subjectNames': ['Matematika', 'Bahasa Inggris'],
    'weeklyProgress': progress,
    'targetCount': count,
    'weekStartDate': '2026-10-12',
    'weekEndDate': '2026-10-18',
    'timezone': 'Asia/Jakarta',
  },
};

void main() {
  test(
    'list mapping preserves canonical percentages and immutable subjects',
    () {
      final student = StudentModel(record()).toEntity();
      expect(student.learningSummary!.weeklyProgress, 53);
      expect(student.learningSummary!.subjectNames, [
        'Matematika',
        'Bahasa Inggris',
      ]);
      expect(student.learningSummary!.weekStartDate, '2026-10-12');
      expect(
        () => student.learningSummary!.subjectNames.add('IPA'),
        throwsUnsupportedError,
      );
      expect(
        StudentModel(
          record(progress: 0),
        ).toEntity().learningSummary!.weeklyProgress,
        0,
      );
      expect(
        StudentModel(
          record(progress: null, count: 0),
        ).toEntity().learningSummary!.weeklyProgress,
        isNull,
      );
      final legacy = record()..remove('learningSummary');
      expect(StudentModel(legacy).toEntity().learningSummary, isNull);
    },
  );

  Future<void> render(
    WidgetTester tester,
    Student student, {
    VoidCallback? onTap,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: StudentListCard(student: student, onTap: onTap ?? () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('weekly row shows backend subjects/progress and opens detail', (
    tester,
  ) async {
    var opened = false;
    await render(
      tester,
      StudentModel(record()).toEntity(),
      onTap: () => opened = true,
    );
    expect(find.text('Andi Saputra'), findsOneWidget);
    expect(find.text('Kelas 6 · Matematika · Bahasa Inggris'), findsOneWidget);
    expect(find.text('Progres minggu ini'), findsOneWidget);
    expect(find.text('53%'), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
    expect(
      tester
          .widget<StudentListProgressBar>(find.byType(StudentListProgressBar))
          .progress,
      53,
    );
    await tester.tap(find.text('Andi Saputra'));
    expect(opened, isTrue);
  });

  testWidgets(
    'zero is displayed, empty targets and missing data are not zero',
    (tester) async {
      await render(tester, StudentModel(record(progress: 0)).toEntity());
      expect(find.text('0%'), findsOneWidget);
      await render(
        tester,
        StudentModel(record(progress: null, count: 0)).toEntity(),
      );
      expect(find.text('Belum ada target minggu ini'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
      final legacy = record()..remove('learningSummary');
      await render(tester, StudentModel(legacy).toEntity());
      expect(find.text('Progres belum tersedia'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
    },
  );

  testWidgets(
    'short student rows are compact with a smaller avatar and a single green progress fill',
    (tester) async {
      final value = record(progress: 30);
      (value['learningSummary'] as Map<String, dynamic>)['subjectNames'] = [
        'Matematika',
      ];
      await render(tester, StudentModel(value).toEntity());
      expect(
        tester.getSize(find.byType(StudentListCard)).height,
        lessThanOrEqualTo(110),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('student-avatar-s1'))).width,
        StudentsStyle.listAvatarSize,
      );
      final bar = tester.widget<NalaraProgressBar>(
        find.byType(NalaraProgressBar),
      );
      expect(bar.progress, 30);
      expect(bar.height, 6);
      expect(bar.accentColor, isNull);
      expect(bar.backgroundColor, StudentsStyle.listProgressTrack);
      expect(
        find.byKey(const ValueKey('nalara-progress-accent')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'archived rows, long names and multiple subjects wrap on narrow screens',
    (tester) async {
      final value = record(progress: 100)
        ..['name'] = 'Nama siswa panjang yang tetap terbaca seluruhnya'
        ..['status'] = 'archived';
      await render(tester, StudentModel(value).toEntity(), scale: 2);
      expect(find.text('Diarsipkan'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
