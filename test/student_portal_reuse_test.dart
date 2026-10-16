import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/student_portal/presentation/pages/student_pages.dart';
import 'package:nalara/features/student_portal/domain/repositories/student_portal_repository.dart';
import 'package:nalara/features/student_portal/data/models/student_portal_models.dart';
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/presentation/pages/learning_pages.dart';
import 'package:nalara/features/lesson_reports/domain/entities/lesson_report.dart';
import 'package:nalara/features/lesson_reports/presentation/pages/reports_pages.dart';
import 'package:nalara/features/profile/presentation/pages/more_page.dart';
import 'package:nalara/features/profile/presentation/pages/help_page.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/presentation/widgets/student_profile_card.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

class _StudentRepository extends StudentPortalRepository {
  @override
  Future<Student> profile() async => const Student(
    id: 'self',
    name: 'Alya',
    grade: 'Kelas 6',
    notes: 'Privat Guru',
    status: 'active',
  );
  @override
  Future<PageResult<LearningPlan>> plans({
    int page = 1,
    String? search,
  }) async => PageResult(items: [], total: 0, page: page, limit: 100);
  @override
  Future<PageResult<LessonReport>> reports({int page = 1}) async =>
      PageResult(items: [], total: 0, page: page, limit: 100);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(
    () =>
        getIt.registerSingleton<StudentPortalRepository>(_StudentRepository()),
  );
  tearDown(() => getIt.reset());
  Future<void> render(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: child));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'student target tab uses the teacher page without creation actions',
    (tester) async {
      await render(tester, const StudentTargetsPage());
      final shared = tester.widget<LearningPlansPage>(
        find.byType(LearningPlansPage),
      );
      expect(shared.readOnly, isTrue);
      expect(shared.loadPlans, isNotNull);
      expect(shared.routePrefix, '/student');
      expect(find.text('Tambah sekarang'), findsNothing);
      expect(
        find.text('Lihat rencana dan target belajar Anda'),
        findsOneWidget,
      );
    },
  );
  testWidgets('student reports reuse the published-only teacher composition', (
    tester,
  ) async {
    await render(tester, const StudentReportsPage());
    final shared = tester.widget<ReportsPage>(find.byType(ReportsPage));
    expect(shared.readOnly, isTrue);
    expect(shared.loadReports, isNotNull);
    expect(find.text('Draft'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
  testWidgets(
    'student menu uses the teacher menu with only authorized routes',
    (tester) async {
      await render(tester, const StudentMorePage());
      final shared = tester.widget<MorePage>(find.byType(MorePage));
      expect(shared.items.map((item) => item.route), [
        '/student/attendance',
        '/student/materials',
        '/student/notifications',
        '/student/profile',
        '/student/help',
      ]);
      expect(find.text('Ganti pengguna'), findsOneWidget);
      expect(find.text('Orang Tua & Keluarga'), findsNothing);
    },
  );
  testWidgets(
    'own profile reuses teacher student card, without notes or edit',
    (tester) async {
      await render(tester, const StudentProfilePage());
      final profile = tester.widget<StudentProfileCard>(
        find.byType(StudentProfileCard),
      );
      expect(profile.student.id, 'self');
      expect(profile.showInternalNotes, isFalse);
      expect(profile.onEdit, isNull);
      expect(find.text('Privat Guru'), findsNothing);
      expect(find.text('Edit profil'), findsNothing);
    },
  );
  testWidgets(
    'help reuses the teacher page but has no teacher or family destinations',
    (tester) async {
      await render(tester, const StudentHelpPage());
      final shared = tester.widget<HelpPage>(find.byType(HelpPage));
      expect(shared.routePrefix, '/student');
      expect(
        shared.topics
            .where((topic) => topic.route != null)
            .every((topic) => topic.route!.startsWith('/student/')),
        isTrue,
      );
    },
  );
  test('student target parser accepts public history with no actor ID', () {
    final detail = StudentTargetDetailModel({
      '_id': 'target',
      'studentId': 'self',
      'planId': 'plan',
      'subjectId': 'math',
      'title': 'Pecahan',
      'description': '',
      'successCriteria': '',
      'priority': 'normal',
      'status': 'active',
      'progress': 30,
      'version': 1,
      'studentName': 'Alya',
      'subjectName': 'Matematika',
      'plan': {
        '_id': 'plan',
        'title': 'Mingguan',
        'startAt': '2026-10-12T00:00:00Z',
        'endAt': '2026-10-18T00:00:00Z',
      },
      'history': [
        {
          '_id': 'h1',
          'targetId': 'target',
          'before': 0,
          'after': 30,
          'note': 'Dibagikan',
          'visibility': 'student',
          'createdAt': '2026-10-16T00:00:00Z',
        },
      ],
    }).toEntity();
    expect(detail.history.single.actorId, '');
    expect(detail.history.single.after, 30);
    expect(detail.subjectName, 'Matematika');
  });
}
