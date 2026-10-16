import '../../../../shared/domain/page.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/schedules_repository.dart';
import '../datasources/schedules_remote_source.dart';
import '../models/lesson_model.dart';

class SchedulesRepositoryImpl implements SchedulesRepository {
  final SchedulesRemoteSource remote;
  SchedulesRepositoryImpl(this.remote);
  @override
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
    String? studentId,
    String? scheduleId,
  }) async {
    final json = await remote.sessions({
      'page': page,
      'from': ?from?.toUtc().toIso8601String(),
      'to': ?to?.toUtc().toIso8601String(),
      'studentId': ?studentId,
      'scheduleId': ?scheduleId,
    });
    final items =
        (json['items'] as List)
            .map((e) => LessonModel(Map<String, dynamic>.from(e)).toEntity())
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return PageResult(
      items: items,
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
    );
  }

  @override
  Future<Lesson> session(String id) async =>
      LessonModel(await remote.session(id)).toEntity();
  @override
  Future<Schedule> schedule(String id) async =>
      ScheduleModel(await remote.schedule(id)).toEntity();
  @override
  Future<Schedule> create(ScheduleDraft d) async => ScheduleModel(
    await remote.create({
      'studentId': d.studentId,
      'subjectId': d.subjectId,
      'startAt': d.startAt.toUtc().toIso8601String(),
      'endAt': d.endAt.toUtc().toIso8601String(),
      'timezone': d.timezone,
      'recurrence': d.repeatCount > 1 ? 'weekly' : 'none',
      'repeatCount': d.repeatCount,
    }),
  ).toEntity();
  @override
  Future<void> reschedule(String id, DateTime startAt, DateTime endAt) =>
      remote.updateSession(id, {
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
      });
  @override
  Future<void> cancelSession(String id) =>
      remote.updateSession(id, {'status': 'cancelled'});
  @override
  Future<void> cancelSeries(String scheduleId) =>
      remote.cancelSeries(scheduleId);
  @override
  Future<void> attendance(String id, String status) =>
      remote.attendance(id, status);
}
