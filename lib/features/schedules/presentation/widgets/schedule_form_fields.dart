import 'package:flutter/material.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../shared/widgets/nalara_pickers.dart';
import 'schedule_form_style.dart';

class ScheduleFormSection extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  const ScheduleFormSection({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: NalaraSurfaceCard(
      radius: 15,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: ScheduleFormStyle.label),
          const SizedBox(height: 9),
          child,
        ],
      ),
    ),
  );
}

class ScheduleDateTimeCard extends StatelessWidget {
  final String label, timezone;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  const ScheduleDateTimeCard({
    super.key,
    required this.label,
    required this.timezone,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  Future<void> _pick(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final local = DateTimeUtils.local(value, timezone);
    final date = await showNalaraDatePicker(
      context: context,
      initialDate: local,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showNalaraTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
    );
    if (time == null || !context.mounted) return;
    onChanged(
      DateTimeUtils.fromWallTime(date, time.hour, time.minute, timezone),
    );
  }

  @override
  Widget build(BuildContext context) => ScheduleFormSection(
    label: label,
    onTap: enabled ? () => _pick(context) : null,
    child: Row(
      children: [
        Container(
          width: 34,
          height: 38,
          decoration: BoxDecoration(
            color: ScheduleFormStyle.paleGreen,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.schedule_rounded,
            size: 22,
            color: ScheduleFormStyle.green,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateTimeUtils.date(value, timezone),
                style: const TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: ScheduleFormStyle.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateTimeUtils.time(value, timezone),
                style: ScheduleFormStyle.supporting,
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: ScheduleFormStyle.ink,
        ),
      ],
    ),
  );
}
