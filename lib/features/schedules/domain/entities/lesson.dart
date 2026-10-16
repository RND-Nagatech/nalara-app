class Lesson {
  final String id, scheduleId, studentId, subjectId, status, attendance;
  final DateTime startAt, endAt;
  final String studentName, studentGrade, subjectName, teacherName;
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
  });
}

class Schedule {
  final String id, studentId, subjectId, timezone, recurrence, status;
  final int repeatCount;
  final DateTime startAt, endAt;
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
  });
}

class ScheduleDraft {
  final String studentId, subjectId, timezone;
  final DateTime startAt, endAt;
  final int repeatCount;
  const ScheduleDraft({
    required this.studentId,
    required this.subjectId,
    required this.startAt,
    required this.endAt,
    this.timezone = 'Asia/Jakarta',
    this.repeatCount = 1,
  });
}
