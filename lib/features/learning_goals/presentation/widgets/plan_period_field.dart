import 'package:flutter/material.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../shared/widgets/nalara_pickers.dart';
import 'plan_form_style.dart';

class PlanPeriodField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  const PlanPeriodField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  Future<void> _pick(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final local = DateTimeUtils.local(value);
    final day = DateTime(local.year, local.month, local.day);
    final date = await showNalaraDatePicker(
      context: context,
      initialDate: day,
      firstDate: day.isBefore(DateTime(2020)) ? day : DateTime(2020),
      lastDate: day.isAfter(DateTime(2100)) ? day : DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    onChanged(DateTimeUtils.fromWallTime(date, 0, 0));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PlanFormLabel(label, requiredField: true),
      Semantics(
        label: label,
        child: OutlinedButton(
          onPressed: enabled ? () => _pick(context) : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(8),
            side: const BorderSide(color: PlanFormStyle.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PlanFormStyle.paleGreen,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.calendar_today_outlined, size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  DateTimeUtils.date(value),
                  style: PlanFormStyle.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: PlanFormStyle.ink,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
