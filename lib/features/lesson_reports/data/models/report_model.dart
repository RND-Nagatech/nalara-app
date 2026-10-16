import '../../domain/entities/lesson_report.dart';

class ReportModel {
  final Map<String, dynamic> json;
  ReportModel(this.json);
  LessonReport toEntity() => LessonReport(
    id: json['_id'],
    sessionId: json['sessionId'],
    studentId: json['studentId'],
    topic: json['topic'],
    summary: json['summary'],
    observations: json['observations'] ?? '',
    difficulties: json['difficulties'] ?? '',
    homework: json['homework'] ?? '',
    recommendation: json['recommendation'] ?? '',
    visibility: json['visibility'],
    status: json['status'],
    studentName: json['studentName'] ?? '',
    subjectName: json['subjectName'] ?? '',
    targetIds: List<String>.from(json['targetIds'] ?? []),
    publishedAt: json['publishedAt'] == null
        ? null
        : DateTime.parse(json['publishedAt']),
  );
}
