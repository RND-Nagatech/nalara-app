class ProgressRecord {
  final String id, targetId, note, actorId, visibility;
  final int before, after;
  final DateTime createdAt;
  final String? sessionId;
  const ProgressRecord({
    required this.id,
    required this.targetId,
    required this.note,
    required this.actorId,
    required this.visibility,
    required this.before,
    required this.after,
    required this.createdAt,
    this.sessionId,
  });
}
