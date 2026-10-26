import '../../../../shared/domain/page.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/schedules_repository.dart';
import '../../domain/repositories/schedule_repeat_repository.dart';
import '../../domain/entities/schedule_repeat.dart';
import '../datasources/schedules_remote_source.dart';
import '../models/lesson_model.dart';

class SchedulesRepositoryImpl
    implements SchedulesRepository, ScheduleRepeatRepository {
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
      'studentIds': d.selectedStudentIds,
      'subjectId': d.subjectId,
      'startAt': d.startAt.toUtc().toIso8601String(),
      'endAt': d.endAt.toUtc().toIso8601String(),
      'timezone': d.timezone,
      'recurrence': d.repeat != null || d.repeatCount > 1 ? 'weekly' : 'none',
      'repeatCount': d.repeatCount,
      if (d.repeat != null) ..._repeatFields(d.repeat!),
    }),
  ).toEntity();
  @override
  Future<void> reschedule(String id, DateTime startAt, DateTime endAt) =>
      remote.updateSession(id, {
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
      });
  @override
  Future<void> cancelSession(String id, String reason) => remote.updateSession(
    id,
    {'status': 'cancelled', 'cancellationReason': reason.trim()},
  );
  @override
  Future<void> cancelSeries(String scheduleId, String reason) =>
      remote.cancelSeries(scheduleId, reason.trim());
  Map<String, dynamic> _repeatFields(ScheduleRepeat repeat) => {
    'repeatDays': repeat.days.toList()..sort(),
    'repeatEnd': repeat.end.name,
    if (repeat.end == ScheduleRepeatEnd.count) 'repeatCount': repeat.count,
    if (repeat.end == ScheduleRepeatEnd.until) 'repeatUntil': repeat.until,
  };
  @override
  Future<Schedule> changeRepeat(
    String id,
    DateTime start,
    DateTime end,
    String timezone,
    ScheduleRepeat repeat,
  ) async => ScheduleModel(
    await remote.changeRepeat(id, {
      'startAt': start.toUtc().toIso8601String(),
      'endAt': end.toUtc().toIso8601String(),
      'timezone': timezone,
      ..._repeatFields(repeat),
    }),
  ).toEntity();
  @override
  Future<String> rescheduleFollowing(
    String sessionId,
    DateTime start,
    DateTime end,
  ) async {
    final result = await remote.changeFollowing(sessionId, {
      'scope': 'following',
      'startAt': start.toUtc().toIso8601String(),
      'endAt': end.toUtc().toIso8601String(),
    });
    return result['continuationScheduleId'] as String;
  }

  @override
  Future<void> cancelFollowing(String sessionId, String reason) =>
      remote.updateSession(sessionId, {
        'scope': 'following',
        'status': 'cancelled',
        'cancellationReason': reason.trim(),
      });
  @override
  Future<void> attendance(String id, String status) =>
      remote.attendance(id, status);
  @override
  Future<void> attendanceBatch(String id, List<AttendanceSelection> entries) =>
      remote.attendanceBatch(
        id,
        entries
            .map(
              (entry) => {
                'sessionId': entry.sessionId,
                'attendance': entry.attendance,
              },
            )
            .toList(),
      );
}
