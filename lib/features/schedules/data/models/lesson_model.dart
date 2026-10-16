import '../../domain/entities/lesson.dart';

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
  );
}
