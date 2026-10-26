import '../entities/lesson.dart';
import '../entities/schedule_repeat.dart';

abstract class ScheduleRepeatRepository {
  Future<Schedule> changeRepeat(
    String id,
    DateTime start,
    DateTime end,
    String timezone,
    ScheduleRepeat repeat,
  );
  Future<String> rescheduleFollowing(
    String sessionId,
    DateTime start,
    DateTime end,
  );
  Future<void> cancelFollowing(String sessionId, String reason);
}
