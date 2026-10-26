import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_repeat.dart';

class LessonModel {
  final Map<String, dynamic> json;
  LessonModel(this.json);
  Lesson toEntity() => Lesson(
    id: json['_id'],
    scheduleId: json['scheduleId'],
    studentId: json['studentId'],
    subjectId: json['subjectId'],
    startAt: DateTime.parse(json['startAt']),
    endAt: DateTime.parse(json['endAt']),
    status: json['status'],
    attendance: json['attendance'],
    studentName: json['studentName'] ?? '',
    studentGrade: json['studentGrade'] ?? '',
    subjectName: json['subjectName'] ?? '',
    teacherName: json['teacherName'] ?? '',
    studentAvatarId: json['studentAvatarId'] as String?,
    cancellationReason: json['cancellationReason'] as String?,
    participants: List.unmodifiable(
      (json['participants'] as List? ?? const []).map(
        (row) => SessionParticipant(
          sessionId: row['sessionId'],
          studentId: row['studentId'],
          studentName: row['studentName'] ?? '',
          studentAvatarId: row['studentAvatarId'],
          attendance: row['attendance'],
          status: row['status'],
          cancellationReason: row['cancellationReason'] as String?,
        ),
      ),
    ),
  );
}

class ScheduleModel {
  final Map<String, dynamic> json;
  ScheduleModel(this.json);
  Schedule toEntity() => Schedule(
    id: json['_id'],
    studentId: json['studentId'],
    subjectId: json['subjectId'],
    timezone: json['timezone'],
    recurrence: json['recurrence'],
    status: json['status'],
    repeatCount: json['repeatCount'],
    startAt: DateTime.parse(json['startAt']),
    endAt: DateTime.parse(json['endAt']),
    participantCount: json['participantCount'] as int? ?? 1,
    repeat: json['repeatEnd'] == null
        ? null
        : ScheduleRepeat(
            days: Set<int>.from(json['repeatDays'] ?? const []),
            end: ScheduleRepeatEnd.values.byName(json['repeatEnd']),
            count: json['repeatCount'] as int? ?? 8,
            until: json['repeatUntil'] as String?,
          ),
    nextStartAt: DateTime.tryParse(json['nextStartAt'] as String? ?? ''),
    nextEndAt: DateTime.tryParse(json['nextEndAt'] as String? ?? ''),
    recurrenceError: json['recurrenceError'] as String?,
    cancellationReason: json['cancellationReason'] as String?,
  );
}
