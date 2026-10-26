import '../../domain/entities/learning_goal.dart';

class TargetModel {
  final Map<String, dynamic> json;
  TargetModel(this.json);
  LearningTarget toEntity() => LearningTarget(
    id: json['_id'],
    planId: json['planId'],
    studentId: json['studentId'],
    subjectId: json['subjectId'],
    title: json['title'],
    description: json['description'] ?? '',
    successCriteria: json['successCriteria'] ?? '',
    status: json['status'],
    priority: json['priority'],
    progress: json['progress'],
    version: json['version'],
    planProgress: (json['plan'] as Map?)?['progress'],
  );
}

class PlanModel {
  final Map<String, dynamic> json;
  PlanModel(this.json);
  LearningPlan toEntity() => LearningPlan(
    id: json['_id'],
    studentId: json['studentId'],
    subjectId: json['subjectId'],
    title: json['title'],
    startAt: DateTime.parse(json['startAt']),
    endAt: DateTime.parse(json['endAt']),
    progress: json['progress'],
    targetCount: json['targetCount'] ?? 0,
    studentName: json['studentName'] ?? '',
    subjectName: json['subjectName'] ?? '',
    studentAvatarId: json['studentAvatarId'] as String?,
    targets: ((json['targets'] as List?) ?? [])
        .map((e) => TargetModel(Map<String, dynamic>.from(e)).toEntity())
        .toList(),
  );
}
