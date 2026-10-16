import '../../domain/entities/student_summary.dart';

class StudentSummaryModel {
  final Map<String, dynamic> json;
  StudentSummaryModel(this.json);
  StudentSummary toEntity() {
    final overall = json['overall'] as Map, weekly = json['weekly'] as Map;
    return StudentSummary(
      studentId: json['studentId'] as String,
      timezone: json['timezone'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      progress: overall['progress'] as int?,
      targetCount: overall['targetCount'] as int,
      weekStartDate: weekly['startDate'] as String,
      weekEndDate: weekly['endDate'] as String,
      weeklyTargetCount: weekly['targetCount'] as int,
      weeklyCompletedCount: weekly['completedCount'] as int,
      weeklyCompletionProgress: weekly['completionProgress'] as int?,
      trend: (json['trend'] as List)
          .map(
            (point) => StudentProgressPoint(
              date: point['date'] as String,
              progress: point['progress'] as int,
            ),
          )
          .toList(),
    );
  }
}
