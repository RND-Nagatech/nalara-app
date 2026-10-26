import 'package:flutter/material.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../shared/widgets/nalara_avatar.dart';
import '../../../../shared/widgets/nalara_progress_bar.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
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
    child: Container(
      decoration: NalaraCardStyle.decoration(
        radius: LearningPlansStyle.listRadius,
      ),
      child: LearningPlanRow(
        plan: plan,
        progressLabel: progressLabel,
        onTap: onTap,
        borderRadius: BorderRadius.circular(LearningPlansStyle.listRadius),
      ),
    ),
  );
}

/// A compact row without its own card border/shadow, usable in grouped lists.
class LearningPlanRow extends StatelessWidget {
  final LearningPlan plan;
  final String progressLabel;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final bool showDivider;
  const LearningPlanRow({
    super.key,
    required this.plan,
    required this.progressLabel,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: borderRadius,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: LearningPlansStyle.listRowPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    key: ValueKey('plan-avatar-${plan.id}'),
                    width: LearningPlansStyle.listAvatarSize,
                    height: LearningPlansStyle.listAvatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LearningPlansStyle.lightGreen,
                      border: Border.all(
                        color: const Color(0xFFF2F3E9),
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: NalaraAvatar(
                      name: plan.studentName,
                      avatarId: plan.studentAvatarId,
                      size: LearningPlansStyle.listAvatarSize - 6,
                      backgroundColor: LearningPlansStyle.lightGreen,
                    ),
                  ),
                ),
                const SizedBox(width: LearningPlansStyle.listAvatarGap),
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
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                                color: LearningPlansStyle.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const ExcludeSemantics(
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: LearningPlansStyle.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          plan.studentName,
                          plan.subjectName,
                        ].where((label) => label.isNotEmpty).join(' · '),
                        style: LearningPlansStyle.body.copyWith(
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateTimeUtils.date(plan.startAt)} – ${DateTimeUtils.date(plan.endAt)}',
                        style: LearningPlansStyle.body.copyWith(
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            '${plan.targetCount} target',
                            style: LearningPlansStyle.body.copyWith(
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            progressLabel,
                            style: LearningPlansStyle.body.copyWith(
                              fontSize: 12,
                              height: 1.4,
                              color: LearningPlansStyle.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (plan.progress != null) ...[
                        const SizedBox(height: 6),
                        NalaraProgressBar(
                          progress: plan.progress,
                          semanticsLabel: 'Progress keseluruhan',
                          fillColor: LearningPlansStyle.green,
                          backgroundColor: LearningPlansStyle.listProgressTrack,
                          accentColor: null,
                          height: 6,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(
              left: LearningPlansStyle.listDividerInset,
              right: 16,
            ),
            child: Divider(
              key: ValueKey('plan-divider-${plan.id}'),
              height: 1,
              thickness: 1,
              color: LearningPlansStyle.listDivider,
            ),
          ),
      ],
    ),
  );
}
