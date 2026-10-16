import '../../domain/entities/reschedule_request.dart';

class RescheduleRequestModel {
  final Map<String, dynamic> json;
  RescheduleRequestModel(this.json);

  RescheduleRequest toEntity() => RescheduleRequest(
    id: json['_id'] as String,
    sessionId: json['sessionId'] as String,
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String? ?? '',
    studentGrade: json['studentGrade'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    status: json['status'] as String,
    oldStartAt: DateTime.parse(json['oldStartAt'] as String),
    oldEndAt: DateTime.parse(json['oldEndAt'] as String),
    requestedStartAt: DateTime.parse(json['requestedStartAt'] as String),
    requestedEndAt: DateTime.parse(json['requestedEndAt'] as String),
    proposedStartAt: _date('proposedStartAt'),
    proposedEndAt: _date('proposedEndAt'),
    reviewNote: json['reviewNote'] as String? ?? '',
  );

  DateTime? _date(String field) =>
      json[field] == null ? null : DateTime.parse(json[field] as String);
}

class RescheduleSlotModel {
  final Map<String, dynamic> json;
  RescheduleSlotModel(this.json);

  RescheduleSlot toEntity() => RescheduleSlot(
    startAt: DateTime.parse(json['startAt'] as String),
    endAt: DateTime.parse(json['endAt'] as String),
  );
}
