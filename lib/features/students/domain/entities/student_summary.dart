class StudentProgressPoint {
  final String date;
  final int progress;
  const StudentProgressPoint({required this.date, required this.progress});
}

class StudentSummary {
  final String studentId, timezone, weekStartDate, weekEndDate;
  final DateTime generatedAt;
  final int? progress, weeklyCompletionProgress;
  final int targetCount, weeklyTargetCount, weeklyCompletedCount;
  final List<StudentProgressPoint> trend;
  StudentSummary({
    required this.studentId,
    required this.timezone,
    required this.generatedAt,
    required this.progress,
    required this.targetCount,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.weeklyTargetCount,
    required this.weeklyCompletedCount,
    required this.weeklyCompletionProgress,
    required List<StudentProgressPoint> trend,
  }) : trend = List.unmodifiable(trend);
}
