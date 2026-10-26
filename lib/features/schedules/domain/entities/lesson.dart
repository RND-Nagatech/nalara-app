import 'schedule_repeat.dart';

class Lesson {
  final String id, scheduleId, studentId, subjectId, status, attendance;
  final DateTime startAt, endAt;
  final String studentName, studentGrade, subjectName, teacherName;
  final String? studentAvatarId;
  final String? cancellationReason;
  final List<SessionParticipant> participants;
  bool get isGroup => participants.length > 1;
  bool get canManageTime => !participants.any((p) => p.status == 'completed');
  String get attendanceSummary => isGroup
      ? '${participants.where((p) => p.attendance != 'pending').length}/${participants.length} presensi tercatat'
      : '';
  const Lesson({
    required this.id,
    required this.scheduleId,
    required this.studentId,
    required this.subjectId,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.attendance,
    this.studentName = '',
    this.studentGrade = '',
    this.subjectName = '',
    this.teacherName = '',
    this.studentAvatarId,
    this.cancellationReason,
    this.participants = const [],
  });
}

class SessionParticipant {
  final String sessionId, studentId, studentName, attendance, status;
  final String? studentAvatarId;
  final String? cancellationReason;
  const SessionParticipant({
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.attendance,
    required this.status,
    this.studentAvatarId,
    this.cancellationReason,
  });
  bool get editable => attendance == 'pending' && status == 'scheduled';
}

class AttendanceSelection {
  final String sessionId, attendance;
  const AttendanceSelection(this.sessionId, this.attendance);
}

class Schedule {
  final String id, studentId, subjectId, timezone, recurrence, status;
  final int repeatCount;
  final int participantCount;
  final DateTime startAt, endAt;
  final ScheduleRepeat? repeat;
  final DateTime? nextStartAt, nextEndAt;
  final String? recurrenceError;
  final String? cancellationReason;
  const Schedule({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.timezone,
    required this.recurrence,
    required this.status,
    required this.repeatCount,
    required this.startAt,
    required this.endAt,
    this.participantCount = 1,
    this.repeat,
    this.nextStartAt,
    this.nextEndAt,
    this.recurrenceError,
    this.cancellationReason,
  });
}

class ScheduleDraft {
  final String studentId, subjectId, timezone;
  final List<String> studentIds;
  List<String> get selectedStudentIds =>
      studentIds.isNotEmpty ? studentIds : [studentId];
  final DateTime startAt, endAt;
  final int repeatCount;
  final ScheduleRepeat? repeat;
  const ScheduleDraft({
    this.studentId = '',
    this.studentIds = const [],
    required this.subjectId,
    required this.startAt,
    required this.endAt,
    this.timezone = 'Asia/Jakarta',
    this.repeatCount = 1,
    this.repeat,
  });
}
