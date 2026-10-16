import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/dashboard/domain/entities/dashboard.dart';
import 'package:nalara/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';

Lesson homeLesson(String id, int hour) => Lesson(
  id: id,
  scheduleId: 'schedule-$id',
  studentId: 'student-$id',
  subjectId: 'subject-$id',
  startAt: DateTime.utc(2026, 10, 14, hour),
  endAt: DateTime.utc(2026, 10, 14, hour + 1),
  status: 'scheduled',
  attendance: 'pending',
  subjectName: 'Pelajaran $id',
  studentName: 'Siswa $id',
  studentGrade: 'Kelas 6',
);

TeacherDashboard homeOverview({
  String name = 'Bu Nara',
  List<Lesson>? lessons,
  int active = 27,
  int today = 9,
  int pending = 4,
  int unread = 2,
}) => TeacherDashboard(
  teacher: Teacher(
    id: 'teacher',
    name: name,
    email: 'teacher@example.test',
    workspaceId: 'workspace',
    timezone: 'Asia/Jakarta',
  ),
  generatedAt: DateTime.utc(2026, 10, 14, 2),
  activeStudents: active,
  sessionsToday: today,
  pendingReports: pending,
  unreadNotifications: unread,
  todaySessions:
      lessons ??
      [
        homeLesson('d', 7),
        homeLesson('b', 3),
        homeLesson('a', 1),
        homeLesson('c', 5),
      ],
  learningPlans: [],
);

class HomeRepositoryFake implements DashboardRepository {
  TeacherDashboard value;
  int calls = 0;
  Object? error;
  Future<TeacherDashboard>? pending;
  HomeRepositoryFake(this.value);
  @override
  Future<TeacherDashboard> get() async {
    calls++;
    if (error != null) throw error!;
    return pending == null ? value : await pending!;
  }
}
