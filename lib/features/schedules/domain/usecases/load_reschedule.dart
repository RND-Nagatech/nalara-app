import '../entities/lesson.dart';
import '../repositories/schedules_repository.dart';

class RescheduleData {
  final Lesson lesson;
  final Schedule schedule;
  const RescheduleData(this.lesson, this.schedule);
}

class LoadReschedule {
  final SchedulesRepository repository;
  const LoadReschedule(this.repository);
  Future<RescheduleData> call(String id) async {
    final lesson = await repository.session(id);
    return RescheduleData(lesson, await repository.schedule(lesson.scheduleId));
  }
}
