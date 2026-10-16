import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/repositories/schedules_repository.dart';
import 'package:nalara/shared/domain/page.dart';

typedef ScheduleRequest = ({int page, DateTime? from, DateTime? to});
Lesson agendaLesson(String id, int day, {int hour = 1}) => Lesson(
  id: id,
  scheduleId: 'schedule-$id',
  studentId: 'student',
  subjectId: 'subject',
  startAt: DateTime.utc(2026, 10, day, hour),
  endAt: DateTime.utc(2026, 10, day, hour + 1),
  status: 'scheduled',
  attendance: 'pending',
  studentName: 'Alya $id',
  studentGrade: 'Kelas 5',
  subjectName: 'Pelajaran $id',
);

class ScheduleRepositoryFake implements SchedulesRepository {
  final calls = <ScheduleRequest>[];
  List<Lesson> records = [];
  int limit = 30;
  Object? error;
  Future<PageResult<Lesson>> Function(ScheduleRequest)? respond;
  @override
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
    String? studentId,
    String? scheduleId,
  }) async {
    final request = (page: page, from: from, to: to);
    calls.add(request);
    if (respond != null) return await respond!(request);
    if (error != null) throw error!;
    final matches =
        records
            .where(
              (lesson) =>
                  (from == null || !lesson.startAt.isBefore(from)) &&
                  (to == null || !lesson.startAt.isAfter(to)),
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return PageResult(
      items: matches.skip((page - 1) * limit).take(limit).toList(),
      total: matches.length,
      page: page,
      limit: limit,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
