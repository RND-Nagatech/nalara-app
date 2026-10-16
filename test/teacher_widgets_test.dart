import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/dashboard/domain/entities/dashboard.dart';
import 'package:nalara/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:nalara/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nalara/features/dashboard/domain/usecases/load_teacher_home.dart';
import 'package:nalara/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/domain/repositories/students_repository.dart';
import 'package:nalara/features/students/domain/usecases/load_students.dart';
import 'package:nalara/features/students/presentation/bloc/students_cubit.dart';
import 'package:nalara/features/students/presentation/pages/students_pages.dart';
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/usecases/update_progress.dart';
import 'package:nalara/features/learning_goals/presentation/widgets/target_card.dart';
import 'package:nalara/features/learning_goals/presentation/widgets/progress_selector.dart';
import 'package:nalara/features/progress_history/domain/entities/progress_record.dart';
import 'package:nalara/features/progress_history/presentation/pages/history_page.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

class FakeDashboard implements DashboardRepository {
  bool fail = false;
  @override
  Future<TeacherDashboard> get() async {
    if (fail) throw Exception('Koneksi terputus');
    return TeacherDashboard(
      generatedAt: DateTime.utc(2026, 10, 14, 2),
      teacher: const Teacher(
        id: 't',
        name: 'Bu Nara',
        email: 'guru@example.test',
        workspaceId: 'w',
        timezone: 'Asia/Jakarta',
      ),
      activeStudents: 0,
      sessionsToday: 0,
      pendingReports: 0,
      unreadNotifications: 0,
      todaySessions: [],
      learningPlans: [],
    );
  }
}

class FakeStudents implements StudentsRepository {
  bool empty = false;
  @override
  Future<PageResult<Student>> list({
    int page = 1,
    String search = '',
    String? status,
  }) async => PageResult(
    items: empty
        ? []
        : [
            const Student(
              id: 's1',
              name: 'Alya',
              grade: 'Kelas 5',
              notes: '',
              status: 'active',
            ),
          ],
    total: empty ? 0 : 1,
    page: 1,
    limit: 30,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const target = LearningTarget(
  id: 't1',
  planId: 'p',
  studentId: 's',
  subjectId: 'm',
  title: 'Memahami pecahan',
  description: '',
  successCriteria: 'Mengerjakan 3 soal',
  status: 'active',
  priority: 'normal',
  progress: 20,
  version: 1,
);
Future<void> render(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: page));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() {
    getIt.registerSingleton<DashboardRepository>(FakeDashboard());
    getIt.registerFactory(
      () => DashboardCubit(LoadTeacherHome(getIt<DashboardRepository>())),
    );
    getIt.registerSingleton<StudentsRepository>(FakeStudents());
    getIt.registerFactory(
      () => StudentsCubit(LoadStudents(getIt<StudentsRepository>())),
    );
    getIt.registerSingleton(PlanProgressLabel());
  });
  tearDown(() async {
    await getIt.reset();
  });
  testWidgets(
    'home shows backend empty values without dummy schedules or old quick actions',
    (tester) async {
      await render(tester, const DashboardPage());
      expect(find.text('BU NARA 👋'), findsOneWidget);
      expect(find.text('NALARA'), findsOneWidget);
      expect(find.text('Rabu, 14 Oktober 2026'), findsOneWidget);
      expect(find.text('Siswa aktif'), findsOneWidget);
      expect(find.text('Siswa baru'), findsNothing);
      expect(find.text('Laporan belum selesai'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Belum ada sesi hari ini.'),
        250,
      );
      expect(find.text('Belum ada sesi hari ini.'), findsOneWidget);
    },
  );
  testWidgets('dashboard error can retry', (tester) async {
    (getIt<DashboardRepository>() as FakeDashboard).fail = true;
    await render(tester, const DashboardPage());
    expect(find.textContaining('Koneksi terputus'), findsOneWidget);
    (getIt<DashboardRepository>() as FakeDashboard).fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('BU NARA 👋'), findsOneWidget);
  });
  testWidgets('students list and status are visible', (tester) async {
    await render(tester, const StudentsPage());
    expect(find.text('Alya'), findsOneWidget);
    expect(find.text('Kelas 5'), findsOneWidget);
    expect(find.text('Progres belum tersedia'), findsOneWidget);
  });
  testWidgets('student empty state offers an action', (tester) async {
    (getIt<StudentsRepository>() as FakeStudents).empty = true;
    await render(tester, const StudentsPage());
    expect(find.text('Belum ada siswa yang sesuai pencarian.'), findsOneWidget);
    expect(find.text('Tambah sekarang'), findsOneWidget);
  });
  testWidgets('target card contains progress and textual status', (
    tester,
  ) async {
    await render(
      tester,
      Scaffold(
        body: TargetCard(target: target, onTap: () {}),
      ),
    );
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('Aktif · Prioritas Normal'), findsOneWidget);
    expect(find.text('Mengerjakan 3 soal'), findsOneWidget);
  });
  testWidgets('update progress slider has integer steps within 0 through 100', (
    tester,
  ) async {
    var value = 20;
    await render(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ProgressSelector(
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );
    expect(find.text('20%'), findsOneWidget);
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('progress-slider')),
    );
    expect(slider.min, 0);
    expect(slider.max, 100);
    expect(slider.divisions, 100);
    slider.onChanged!(60.5);
    await tester.pumpAndSettle();
    expect(value, 61);
    expect(find.text('61%'), findsOneWidget);
  });
  testWidgets('history timeline shows before/after and server time', (
    tester,
  ) async {
    await render(
      tester,
      Scaffold(
        body: HistoryRecordCard(
          record: ProgressRecord(
            id: 'h',
            targetId: 't',
            note: 'Semakin mandiri',
            actorId: 'guru',
            visibility: 'shared',
            before: 20,
            after: 60,
            createdAt: DateTime.utc(2026, 10, 13, 8),
          ),
        ),
      ),
    );
    expect(find.text('20% → 60%'), findsOneWidget);
    expect(find.text('Semakin mandiri'), findsOneWidget);
    expect(find.text('13 Okt 2026 · 15:00'), findsOneWidget);
  });
}
