import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../domain/entities/learning_goal.dart';
import 'plan_detail_style.dart';

class TargetCard extends StatelessWidget {
  final LearningTarget target;
  final VoidCallback onTap;
  const TargetCard({super.key, required this.target, required this.onTap});
  @override
  Widget build(BuildContext context) => PlanDetailCard(
    key: ValueKey(target.id),
    onTap: onTap,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      target.title,
                      style: PlanDetailStyle.title.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${target.progress}%',
                    style: PlanDetailStyle.title.copyWith(
                      fontSize: 14,
                      color: PlanDetailStyle.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PlanProgressTrack(progress: target.progress),
              const SizedBox(height: 10),
              Text(
                '${statusLabel(target.status)} · Prioritas ${statusLabel(target.priority)}',
                style: PlanDetailStyle.body.copyWith(
                  color: PlanDetailStyle.ink,
                  fontSize: 12,
                ),
              ),
              if (target.successCriteria.isNotEmpty)
                Text(
                  target.successCriteria,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PlanDetailStyle.body,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF5B6573),
          size: 24,
        ),
      ],
    ),
  );
}
