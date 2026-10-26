import '../../../../shared/domain/page.dart';
import '../entities/lesson.dart';

abstract class SchedulesRepository {
  Future<PageResult<Lesson>> sessions({
    int page = 1,
    DateTime? from,
    DateTime? to,
    String? studentId,
    String? scheduleId,
  });
  Future<Lesson> session(String id);
  Future<Schedule> schedule(String id);
  Future<Schedule> create(ScheduleDraft draft);
  Future<void> reschedule(String id, DateTime startAt, DateTime endAt);
  Future<void> cancelSession(String id, String reason);
  Future<void> cancelSeries(String scheduleId, String reason);
  Future<void> attendance(String id, String status);
  Future<void> attendanceBatch(String id, List<AttendanceSelection> entries);
}
