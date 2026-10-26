enum ScheduleRepeatEnd { never, count, until }

class ScheduleRepeat {
  final Set<int> days;
  final ScheduleRepeatEnd end;
  final int count;
  final String? until;
  ScheduleRepeat({
    required Set<int> days,
    this.end = ScheduleRepeatEnd.never,
    this.count = 8,
    this.until,
  }) : days = Set.unmodifiable(days);
}
