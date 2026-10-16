import 'package:nalara/features/lesson_reports/domain/entities/lesson_report.dart';
import 'package:nalara/features/lesson_reports/domain/repositories/reports_repository.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/domain/entities/student_summary.dart';
import 'package:nalara/features/students/domain/usecases/load_student_overview.dart';
import 'package:nalara/shared/domain/page.dart';
import 'learning_plans_fixtures.dart';
import 'schedule_fixtures.dart';
import 'students_fixtures.dart';

Student detailStudent({
  String id = 's1',
  String name = 'Alya',
  String status = 'active',
  String? familyId,
  String notes = 'Suka membaca',
}) => Student(
  id: id,
  name: name,
  grade: 'Kelas 5',
  notes: notes,
  status: status,
  familyId: familyId,
);

class DetailStudentsFake extends StudentsRepositoryFake {
  Student current = detailStudent();
  final requests = <String>[];
  List<ParentInvitation> codes = [];
  Object? actionError;
  Future<Student> Function(String)? respondGet;
  Future<ParentInvitation> Function()? respondInvite;
  StudentSummary summaryData = StudentSummary(
    studentId: 's1',
    timezone: 'Asia/Jakarta',
    generatedAt: DateTime.utc(2026, 10, 15),
    progress: 53,
    targetCount: 5,
    weekStartDate: '2026-10-12',
    weekEndDate: '2026-10-18',
    weeklyTargetCount: 5,
    weeklyCompletedCount: 3,
    weeklyCompletionProgress: 60,
    trend: const [
      StudentProgressPoint(date: '2026-10-12', progress: 20),
      StudentProgressPoint(date: '2026-10-14', progress: 40),
      StudentProgressPoint(date: '2026-10-15', progress: 53),
    ],
  );
  @override
  Future<StudentSummary> summary(String id) async {
    requests.add('summary:$id');
    if (error != null) throw error!;
    return summaryData;
  }

  @override
  Future<Student> get(String id) async {
    requests.add('get:$id');
    if (respondGet != null) return await respondGet!(id);
    if (error != null) throw error!;
    return current;
  }

  @override
  Future<List<ParentInvitation>> invitations(String id) async {
    requests.add('invitations:$id');
    return codes;
  }

  @override
  Future<ParentInvitation> invite(String id) async {
    requests.add('invite:$id');
    if (actionError != null) throw actionError!;
    if (respondInvite != null) return await respondInvite!();
    final expiresAt = DateTime.utc(2035, 1, 1);
    codes = [ParentInvitation(id: 'code', expiresAt: expiresAt)];
    return ParentInvitation(
      id: 'code',
      token: 'NL-TEST-STUDENT',
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> revoke(String studentId, String invitationId) async {
    requests.add('revoke:$studentId:$invitationId');
    if (actionError != null) throw actionError!;
    codes = [
      for (final code in codes)
        ParentInvitation(
          id: code.id,
          expiresAt: code.expiresAt,
          revokedAt: DateTime.utc(2026, 10, 15),
        ),
    ];
  }

  @override
  Future<void> revokeAccess(String id) async {
    requests.add('revoke-access:$id');
    if (actionError != null) throw actionError!;
  }

  @override
  Future<void> archive(String id) async {
    requests.add('archive:$id');
    if (actionError != null) throw actionError!;
    current = detailStudent(
      id: id,
      name: current.name,
      status: 'archived',
      familyId: current.familyId,
    );
  }
}

class DetailSchedulesFake extends ScheduleRepositoryFake {
  final studentIds = <String?>[];
  @override
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
    String? studentId,
    String? scheduleId,
  }) {
    studentIds.add(studentId);
    return super.sessions(
      page: page,
      from: from,
      to: to,
      studentId: studentId,
      scheduleId: scheduleId,
    );
  }
}

class DetailReportsFake implements ReportsRepository {
  final studentIds = <String?>[];
  List<LessonReport> records = [];
  Object? error;
  @override
  Future<PageResult<LessonReport>> list({
    int page = 1,
    String? studentId,
    String? status,
    String? sessionId,
  }) async {
    studentIds.add(studentId);
    if (error != null) throw error!;
    return PageResult(
      items: records,
      total: records.length,
      page: page,
      limit: 30,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DetailFixtures {
  final students = DetailStudentsFake();
  final learning = LearningRepositoryFake();
  final schedules = DetailSchedulesFake();
  final reports = DetailReportsFake();
  late final load = LoadStudentOverview(students, learning, schedules, reports);
}

const detailReport = LessonReport(
  id: 'r1',
  sessionId: 'lesson',
  studentId: 's1',
  topic: 'Latihan pecahan',
  summary: 'Perkembangan baik',
  observations: '',
  difficulties: '',
  homework: '',
  recommendation: '',
  visibility: 'shared',
  status: 'draft',
  targetIds: [],
);
