class RescheduleRequest {
  final String id,
      sessionId,
      studentId,
      studentName,
      studentGrade,
      reason,
      status;
  final DateTime oldStartAt, oldEndAt, requestedStartAt, requestedEndAt;
  final DateTime? proposedStartAt, proposedEndAt;
  final String reviewNote;

  const RescheduleRequest({
    required this.id,
    required this.sessionId,
    required this.studentId,
    this.studentName = '',
    this.studentGrade = '',
    required this.reason,
    required this.status,
    required this.oldStartAt,
    required this.oldEndAt,
    required this.requestedStartAt,
    required this.requestedEndAt,
    this.proposedStartAt,
    this.proposedEndAt,
    this.reviewNote = '',
  });

  bool get hasProposal => proposedStartAt != null && proposedEndAt != null;
}

class RescheduleSlot {
  final DateTime startAt, endAt;

  const RescheduleSlot({required this.startAt, required this.endAt});

  String get id =>
      '${startAt.toUtc().toIso8601String()}/${endAt.toUtc().toIso8601String()}';
}
