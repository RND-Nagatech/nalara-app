import '../../../students/domain/repositories/students_repository.dart';
import '../entities/plan_overview.dart';
import '../repositories/learning_repository.dart';

class LoadPlanOverview {
  final LearningRepository learning;
  final StudentsRepository students;
  LoadPlanOverview(this.learning, this.students);

  Future<PlanOverview> call(String id) async {
    final plan = await learning.plan(id);
    final student = await students.get(plan.studentId);
    return PlanOverview(plan: plan, student: student);
  }
}
