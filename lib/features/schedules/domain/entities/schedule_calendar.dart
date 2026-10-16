import 'package:timezone/timezone.dart' as tz;
import 'schedule_period.dart';

typedef ScheduleWindow = ({DateTime from, DateTime until});

/// UTC-constructed values represent calendar fields, not UTC instants.
abstract final class ScheduleCalendar {
  static DateTime date(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  static DateTime localDate(DateTime instant, String timezone) =>
      date(tz.TZDateTime.from(instant, tz.getLocation(timezone)));
  static DateTime weekStart(DateTime value) {
    final day = date(value);
    return DateTime.utc(day.year, day.month, day.day - day.weekday + 1);
  }

  static List<DateTime> weekDays(DateTime value) {
    final start = weekStart(value);
    return List.unmodifiable(
      List.generate(
        7,
        (index) => DateTime.utc(start.year, start.month, start.day + index),
      ),
    );
  }

  static List<DateTime?> monthCells(DateTime value) {
    final first = DateTime.utc(value.year, value.month, 1);
    final count = DateTime.utc(value.year, value.month + 1, 0).day;
    final offset = first.weekday - 1;
    final length = ((offset + count + 6) ~/ 7) * 7;
    return List.unmodifiable(
      List.generate(length, (index) {
        final day = index - offset + 1;
        return day < 1 || day > count
            ? null
            : DateTime.utc(value.year, value.month, day);
      }),
    );
  }

  static DateTime move(
    DateTime value,
    SchedulePeriod period,
    int direction, {
    int? preferredDay,
  }) {
    if (period != SchedulePeriod.month) {
      return DateTime.utc(
        value.year,
        value.month,
        value.day + direction * (period == SchedulePeriod.week ? 7 : 1),
      );
    }
    final first = DateTime.utc(value.year, value.month + direction, 1);
    final last = DateTime.utc(first.year, first.month + 1, 0).day;
    return DateTime.utc(
      first.year,
      first.month,
      (preferredDay ?? value.day).clamp(1, last),
    );
  }

  static bool allowed(DateTime value) =>
      value.year >= 2020 && value.year <= 2100;
  static ScheduleWindow window(
    DateTime value,
    SchedulePeriod period,
    String timezone,
  ) {
    final day = date(value);
    final start = switch (period) {
      SchedulePeriod.day => day,
      SchedulePeriod.week => weekStart(day),
      SchedulePeriod.month => DateTime.utc(day.year, day.month, 1),
    };
    final next = period == SchedulePeriod.month
        ? DateTime.utc(start.year, start.month + 1, 1)
        : DateTime.utc(
            start.year,
            start.month,
            start.day + (period == SchedulePeriod.week ? 7 : 1),
          );
    final location = tz.getLocation(timezone);
    DateTime midnight(DateTime calendar) => tz.TZDateTime(
      location,
      calendar.year,
      calendar.month,
      calendar.day,
    ).toUtc();
    return (from: midnight(start), until: midnight(next));
  }
}
