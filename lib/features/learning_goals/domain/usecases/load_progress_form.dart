import '../../../schedules/domain/entities/lesson.dart';
import '../../../schedules/domain/repositories/schedules_repository.dart';
import '../../../students/domain/repositories/students_repository.dart';
import '../entities/progress_form_data.dart';
import '../repositories/learning_repository.dart';

class LoadProgressForm {
  final LearningRepository learning;
  final StudentsRepository students;
  final SchedulesRepository schedules;
  LoadProgressForm(this.learning, this.students, this.schedules);

  Future<ProgressFormData> call(String targetId) async {
    final target = await learning.target(targetId);
    final student = await students.get(target.studentId);
    final plan = await learning.plan(target.planId);
    final lessons = <Lesson>[];
    var page = 1;
    while (true) {
      final result = await schedules.sessions(
        page: page,
        studentId: target.studentId,
      );
      lessons.addAll(
        result.items.where(
          (lesson) =>
              lesson.studentId == target.studentId &&
              lesson.subjectId == target.subjectId &&
              lesson.status != 'cancelled',
        ),
      );
      if (!result.hasNext) break;
      page++;
    }
    lessons.sort((a, b) {
      final time = a.startAt.compareTo(b.startAt);
      return time == 0 ? a.id.compareTo(b.id) : time;
    });
    return ProgressFormData(
      target: target,
      student: student,
      plan: plan,
      lessons: lessons,
    );
  }
}
