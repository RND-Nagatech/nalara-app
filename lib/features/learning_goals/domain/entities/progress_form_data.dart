import '../../../schedules/domain/entities/lesson.dart';
import '../../../students/domain/entities/student.dart';
import 'learning_goal.dart';

class ProgressFormData {
  final LearningTarget target;
  final Student student;
  final LearningPlan plan;
  final List<Lesson> lessons;
  ProgressFormData({
    required this.target,
    required this.student,
    required this.plan,
    required List<Lesson> lessons,
  }) : lessons = List.unmodifiable(lessons);
}
