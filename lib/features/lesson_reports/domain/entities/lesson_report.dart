class LessonReport {
  final String id,
      sessionId,
      studentId,
      topic,
      summary,
      observations,
      difficulties,
      homework,
      recommendation,
      visibility,
      status;
  final List<String> targetIds;
  final String studentName, subjectName;
  final DateTime? publishedAt;
  const LessonReport({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.topic,
    required this.summary,
    required this.observations,
    required this.difficulties,
    required this.homework,
    required this.recommendation,
    required this.visibility,
    required this.status,
    required this.targetIds,
    this.publishedAt,
    this.studentName = '',
    this.subjectName = '',
  });
}

class ReportDraft {
  final String topic,
      summary,
      observations,
      difficulties,
      homework,
      recommendation,
      visibility;
  final List<String> targetIds;
  const ReportDraft({
    required this.topic,
    required this.summary,
    required this.visibility,
    this.observations = '',
    this.difficulties = '',
    this.homework = '',
    this.recommendation = '',
    this.targetIds = const [],
  });
}
