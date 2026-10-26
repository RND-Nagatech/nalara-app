class LearningTarget {
  final String id,
      planId,
      studentId,
      subjectId,
      title,
      description,
      successCriteria,
      status,
      priority;
  final int progress, version;
  final int? planProgress;
  const LearningTarget({
    required this.id,
    required this.planId,
    required this.studentId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.successCriteria,
    required this.status,
    required this.priority,
    required this.progress,
    required this.version,
    this.planProgress,
  });
}

class LearningPlan {
  final String id, studentId, subjectId, title;
  final String studentName, subjectName;
  final String? studentAvatarId;
  final DateTime startAt, endAt;
  final int? progress;
  final int targetCount;
  final List<LearningTarget> targets;
  const LearningPlan({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.progress,
    required this.targetCount,
    this.targets = const [],
    this.studentName = '',
    this.subjectName = '',
    this.studentAvatarId,
  });
}

class TargetDraft {
  final String title, description, successCriteria, priority;
  const TargetDraft({
    required this.title,
    this.description = '',
    this.successCriteria = '',
    this.priority = 'normal',
  });
}

class PlanDraft {
  final String studentId, subjectId, title;
  final DateTime startAt, endAt;
  final List<TargetDraft> targets;
  const PlanDraft({
    required this.studentId,
    required this.subjectId,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.targets,
  });
}

class ProgressUpdate {
  final int progress, version;
  final String note, visibility;
  final String? sessionId;
  const ProgressUpdate({
    required this.progress,
    required this.version,
    required this.note,
    required this.visibility,
    this.sessionId,
  });
}
