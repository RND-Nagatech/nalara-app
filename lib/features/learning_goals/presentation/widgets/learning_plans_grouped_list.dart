import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../domain/entities/learning_goal.dart';
import 'learning_plan_card.dart';
import 'learning_plans_style.dart';

/// One continuous card, with lazy rows retained when more server pages append.
class LearningPlansGroupedList extends StatelessWidget {
  final List<LearningPlan> plans;
  final String Function(LearningPlan) progressLabel;
  final ValueChanged<LearningPlan> onOpen;
  const LearningPlansGroupedList({
    super.key,
    required this.plans,
    required this.progressLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => DecoratedSliver(
    key: const ValueKey('target-plan-group'),
    decoration: NalaraCardStyle.decoration(
      radius: LearningPlansStyle.listRadius,
    ),
    sliver: SliverPadding(
      // Keep the single outer border visible; only the group's end rows round.
      padding: const EdgeInsets.all(1),
      sliver: SliverList.builder(
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          const radius = Radius.circular(LearningPlansStyle.listRadius - 1);
          return LearningPlanRow(
            key: ValueKey(plan.id),
            plan: plan,
            progressLabel: progressLabel(plan),
            onTap: () => onOpen(plan),
            showDivider: index < plans.length - 1,
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? radius : Radius.zero,
              bottom: index == plans.length - 1 ? radius : Radius.zero,
            ),
          );
        },
      ),
    ),
  );
}
