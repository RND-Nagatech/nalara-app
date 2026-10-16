enum SchedulePeriod {
  day,
  week,
  month;

  static SchedulePeriod parse(String value) => switch (value) {
    'week' => week,
    'month' => month,
    _ => day,
  };
}
