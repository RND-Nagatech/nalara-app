import '../../../../shared/domain/page.dart';
import '../entities/lesson.dart';
import '../entities/schedule_calendar.dart';
import '../entities/schedule_period.dart';
import '../repositories/schedules_repository.dart';

typedef ScheduleAgendaSessions =
    Future<PageResult<Lesson>> Function({
      required int page,
      required DateTime from,
      required DateTime to,
    });

class LoadScheduleAgenda {
  final ScheduleAgendaSessions _sessions;

  LoadScheduleAgenda(SchedulesRepository repository)
    : _sessions = repository.sessions;

  LoadScheduleAgenda.fromSessions({required ScheduleAgendaSessions sessions})
    : this._(sessions);

  LoadScheduleAgenda._(this._sessions);

  Future<PageResult<Lesson>> call({
    required DateTime date,
    required SchedulePeriod period,
    required String timezone,
    int page = 1,
  }) async {
    final window = ScheduleCalendar.window(date, period, timezone);
    final result = await _sessions(
      page: page,
      from: window.from,
      // API 'to' is inclusive; Mongo/JS timestamps have millisecond precision.
      to: window.until.subtract(const Duration(milliseconds: 1)),
    );
    final ordered = [...result.items]
      ..sort((left, right) {
        final time = left.startAt.compareTo(right.startAt);
        return time == 0 ? left.id.compareTo(right.id) : time;
      });
    return PageResult(
      items: List.unmodifiable(ordered),
      total: result.total,
      page: result.page,
      limit: result.limit,
    );
  }
}
