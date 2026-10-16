import '../../../students/domain/entities/student.dart';
import 'learning_goal.dart';

class PlanOverview {
  final LearningPlan plan;
  final Student student;
  final List<LearningTarget> targets;
  PlanOverview({required this.plan, required this.student})
    : targets = List.unmodifiable(plan.targets);
}
