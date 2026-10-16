import 'package:flutter/material.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../domain/entities/learning_goal.dart';
import 'learning_plans_style.dart';

class LearningPlanCard extends StatelessWidget {
  final LearningPlan plan;
  final String progressLabel;
  final VoidCallback onTap;
  const LearningPlanCard({
    super.key,
    required this.plan,
    required this.progressLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: NalaraSurfaceCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: LearningPlansStyle.lightGreen,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.flag_rounded,
                size: 22,
                color: LearningPlansStyle.green,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        style: const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 16,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: LearningPlansStyle.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 24,
                        color: LearningPlansStyle.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    plan.studentName,
                    plan.subjectName,
                  ].where((label) => label.isNotEmpty).join(' · '),
                  style: LearningPlansStyle.body.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateTimeUtils.date(plan.startAt)} – ${DateTimeUtils.date(plan.endAt)}',
                  style: LearningPlansStyle.body,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${plan.targetCount} target',
                      style: LearningPlansStyle.body,
                    ),
                    Text(
                      progressLabel,
                      style: LearningPlansStyle.body.copyWith(
                        color: LearningPlansStyle.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (plan.progress != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Progress keseluruhan',
                    value: progressLabel,
                    child: LinearProgressIndicator(
                      value: plan.progress! / 100,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(4),
                      color: LearningPlansStyle.green,
                      backgroundColor: LearningPlansStyle.lightGreen,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
