import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/domain/page.dart';
import '../../../../shared/widgets/student_bottom_navigation.dart';
import '../../../../utils/injector.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../learning_goals/domain/entities/plan_overview.dart';
import '../../../learning_goals/presentation/pages/learning_pages.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../../domain/usecases/load_student_details.dart';

class StudentTargetsPage extends StatelessWidget {
  const StudentTargetsPage({super.key});
  static Future<PageResult<LearningPlan>> _load(int page, String? _) =>
      getIt<StudentPortalRepository>().plans(page: page);
  @override
  Widget build(BuildContext context) => const LearningPlansPage(
    loadPlans: _load,
    readOnly: true,
    routePrefix: '/student',
    subtitle: 'Lihat rencana dan target belajar Anda',
  );
}

class StudentPlanDetailPage extends StatelessWidget {
  final String id;
  const StudentPlanDetailPage({super.key, required this.id});
  static Future<PlanOverview> _load(String id) =>
      LoadStudentDetails(getIt<StudentPortalRepository>()).plan(id);
  @override
  Widget build(BuildContext context) => PlanDetailPage(
    id: id,
    loadPlan: _load,
    readOnly: true,
    routePrefix: '/student',
    studentRoute: '/student/profile',
    bottomNavigationBar: StudentBottomNavigation(
      selectedIndex: 2,
      onDestinationSelected: (index) =>
          context.go(studentNavigationLocations[index]),
    ),
  );
}

class StudentTargetDetailPage extends StatelessWidget {
  final String id;
  const StudentTargetDetailPage({super.key, required this.id});
  static Future<TargetDetailData> _load(String id) async {
    final detail = await getIt<StudentPortalRepository>().target(id);
    return TargetDetailData(
      target: detail.target,
      planTitle: detail.planTitle,
      studentName: detail.studentName,
      subjectName: detail.subjectName,
      startAt: detail.planStartAt,
      endAt: detail.planEndAt,
      history: List.unmodifiable(detail.history),
    );
  }

  @override
  Widget build(BuildContext context) => TargetDetailPage(
    id: id,
    loadTarget: _load,
    readOnly: true,
    routePrefix: '/student',
  );
}
