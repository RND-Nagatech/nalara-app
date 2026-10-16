import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/domain/page.dart';
import '../../../../shared/widgets/parent_bottom_navigation.dart';
import '../../../../utils/injector.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../learning_goals/domain/entities/plan_overview.dart';
import '../../../learning_goals/presentation/pages/learning_pages.dart';
import '../../domain/repositories/parent_portal_repository.dart';

/// The teacher list composition backed exclusively by the family-scoped portal.
class ParentLearningPlansPage extends StatelessWidget {
  final String? studentId;
  const ParentLearningPlansPage({super.key, this.studentId});

  static Future<PageResult<LearningPlan>> _loadPlans(
    int page,
    String? studentId,
  ) => getIt<ParentPortalRepository>().plans(page: page, studentId: studentId);

  @override
  Widget build(BuildContext context) => LearningPlansPage(
    studentId: studentId,
    loadPlans: _loadPlans,
    readOnly: true,
    routePrefix: '/parent',
  );
}

class ParentLearningPlanDetailPage extends StatelessWidget {
  final String id;
  const ParentLearningPlanDetailPage({super.key, required this.id});

  static Future<PlanOverview> _loadPlan(String id) async {
    final parent = getIt<ParentPortalRepository>();
    final plan = await parent.plan(id);
    final detail = await parent.student(plan.studentId);
    return PlanOverview(plan: plan, student: detail.student);
  }

  @override
  Widget build(BuildContext context) => PlanDetailPage(
    id: id,
    loadPlan: _loadPlan,
    readOnly: true,
    routePrefix: '/parent',
    bottomNavigationBar: ParentBottomNavigation(
      selectedIndex: 3,
      onDestinationSelected: (index) =>
          context.go(parentNavigationLocations[index]),
    ),
  );
}

class ParentLearningTargetDetailPage extends StatelessWidget {
  final String id;
  const ParentLearningTargetDetailPage({super.key, required this.id});

  static Future<TargetDetailData> _loadTarget(String id) async {
    final detail = await getIt<ParentPortalRepository>().target(id);
    return TargetDetailData(
      target: detail.target,
      planTitle: detail.planTitle,
      studentName: detail.studentName,
      subjectName: detail.subjectName,
      startAt: detail.startAt,
      endAt: detail.endAt,
      history: List.unmodifiable(detail.history),
    );
  }

  @override
  Widget build(BuildContext context) => TargetDetailPage(
    id: id,
    loadTarget: _loadTarget,
    readOnly: true,
    routePrefix: '/parent',
  );
}
