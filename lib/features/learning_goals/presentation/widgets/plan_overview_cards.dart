import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/plan_overview.dart';
import 'plan_detail_style.dart';

class PlanInformationCard extends StatelessWidget {
  final PlanOverview data;
  final VoidCallback onStudent;
  const PlanInformationCard({
    super.key,
    required this.data,
    required this.onStudent,
  });
  @override
  Widget build(BuildContext context) => PlanDetailCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Lihat siswa',
          child: InkWell(
            key: const ValueKey('plan-open-student'),
            onTap: onStudent,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _value('Siswa', data.student.name, bold: true),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Semantics(
                        label: 'Status siswa',
                        child: Container(
                          key: const ValueKey('plan-student-status'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: data.student.status == 'active'
                                ? PlanDetailStyle.paleGreen
                                : const Color(0xFFF0EEE8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusLabel(data.student.status),
                            style: PlanDetailStyle.body.copyWith(
                              color: PlanDetailStyle.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _divider,
        _value(
          'Bidang belajar',
          data.plan.subjectName.isEmpty ? '—' : data.plan.subjectName,
        ),
        _divider,
        _value(
          'Periode',
          '${DateTimeUtils.date(data.plan.startAt)} – ${DateTimeUtils.date(data.plan.endAt)}',
        ),
      ],
    ),
  );
  static const _divider = Padding(
    padding: EdgeInsets.symmetric(vertical: 11),
    child: Divider(height: 1, thickness: .7, color: Color(0xFFE7E9EB)),
  );
  Widget _value(String label, String value, {bool bold = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: PlanDetailStyle.body),
      Text(
        value,
        style: PlanDetailStyle.body.copyWith(
          color: PlanDetailStyle.ink,
          fontSize: 15,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    ],
  );
}

class PlanAggregateCard extends StatelessWidget {
  final LearningPlan plan;
  const PlanAggregateCard({super.key, required this.plan});
  @override
  Widget build(BuildContext context) => PlanDetailCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text('Progress keseluruhan', style: PlanDetailStyle.title),
            ),
            const SizedBox(width: 12),
            Text(
              plan.progress == null ? '—' : '${plan.progress}%',
              key: const ValueKey('plan-overall-value'),
              style: PlanDetailStyle.title.copyWith(
                color: PlanDetailStyle.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        if (plan.progress != null)
          PlanProgressTrack(
            key: const ValueKey('plan-overall-track'),
            progress: plan.progress!,
          )
        else
          const Text(
            'Belum ada target aktif yang dapat dihitung.',
            style: PlanDetailStyle.body,
          ),
        const SizedBox(height: 25),
        const Text(
          'Setiap target aktif memiliki bobot yang sama.\nTarget yang diarsipkan/dibatalkan tidak dihitung.',
          style: PlanDetailStyle.body,
        ),
      ],
    ),
  );
}
