import '../../domain/entities/progress_record.dart';

class HistoryModel {
  final Map<String, dynamic> json;
  HistoryModel(this.json);
  ProgressRecord toEntity() => ProgressRecord(
    id: json['_id'],
    targetId: json['targetId'],
    note: json['note'] ?? '',
    actorId: json['actorId'],
    visibility: json['visibility'],
    before: json['before'],
    after: json['after'],
    createdAt: DateTime.parse(json['createdAt']),
    sessionId: json['sessionId'],
  );
}
