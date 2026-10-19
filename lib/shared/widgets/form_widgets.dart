import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/color.dart';
import 'nalara_pickers.dart';

class FormFieldSpace extends StatelessWidget {
  final Widget child;
  const FormFieldSpace({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 16), child: child);
}

class DateTimeField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool withTime;
  final String timezone;
  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.withTime = true,
    this.timezone = DateTimeUtils.zone,
  });
  @override
  Widget build(BuildContext context) => FormFieldSpace(
    child: OutlinedButton(
      onPressed: () async {
        final local = DateTimeUtils.local(value, timezone);
        final date = await showNalaraDatePicker(
          context: context,
          initialDate: local,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date == null || !context.mounted) return;
        final time = withTime
            ? await showNalaraTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(local),
              )
            : const TimeOfDay(hour: 0, minute: 0);
        if (time != null && context.mounted) {
          onChanged(
            DateTimeUtils.fromWallTime(date, time.hour, time.minute, timezone),
          );
        }
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: NalaraColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  withTime
                      ? DateTimeUtils.full(value, timezone)
                      : DateTimeUtils.date(value, timezone),
                  style: const TextStyle(color: NalaraColors.ink, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.calendar_today_outlined, size: 19),
        ],
      ),
    ),
  );
}

void finishForm(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop(true);
  } else {
    context.go(fallback);
  }
}

String statusLabel(String status) =>
    const {
      'active': 'Aktif',
      'archived': 'Diarsipkan',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
      'scheduled': 'Terjadwal',
      'pending': 'Belum dicatat',
      'present': 'Hadir',
      'excused': 'Izin',
      'absent': 'Tidak hadir',
      'draft': 'Draft',
      'published': 'Terbit',
      'teacher': 'Internal Guru',
      'student': 'Hanya Siswa',
      'shared': 'Dibagikan',
      'low': 'Rendah',
      'normal': 'Normal',
      'high': 'Tinggi',
    }[status] ??
    status;
