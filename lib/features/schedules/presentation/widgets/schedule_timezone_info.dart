import 'package:flutter/material.dart';
import '../../../../shared/domain/app_timezones.dart';
import 'schedule_form_style.dart';

/// New schedules use the confirmed account zone; settings owns its editor.
class ScheduleTimezoneInfo extends StatelessWidget {
  final String timezone;
  final VoidCallback? onOpenSettings;

  const ScheduleTimezoneInfo({
    super.key,
    required this.timezone,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text.rich(
            key: const ValueKey('schedule-timezone'),
            TextSpan(
              children: [
                TextSpan(
                  text: 'Waktu ${AppTimezones.abbreviation(timezone)}',
                  style: ScheduleFormStyle.supporting.copyWith(
                    color: ScheduleFormStyle.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' · mengikuti Pengaturan'),
              ],
            ),
            style: ScheduleFormStyle.supporting,
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          key: const ValueKey('schedule-timezone-settings'),
          onPressed: onOpenSettings,
          style: TextButton.styleFrom(
            foregroundColor: ScheduleFormStyle.green,
            minimumSize: const Size(48, 44),
            textStyle: ScheduleFormStyle.supporting.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Ubah'),
        ),
      ],
    ),
  );
}
