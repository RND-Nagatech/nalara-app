import 'package:flutter/material.dart';
import '../../../../shared/domain/app_timezones.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/lesson.dart';
import 'session_detail_style.dart';
import 'schedule_repeat_fields.dart';

class ScheduleSeriesSummary extends StatelessWidget {
  final Schedule schedule;
  const ScheduleSeriesSummary({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) => SessionSectionCard(
    children: [
      if (schedule.participantCount > 1) ...[
        Text(
          'Sesi kelompok · ${schedule.participantCount} siswa',
          style: _value,
        ),
        _divider(),
      ],
      _row(
        Icons.calendar_month_outlined,
        'Pertemuan awal',
        Text(
          DateTimeUtils.full(schedule.startAt, schedule.timezone),
          style: _value,
        ),
      ),
      _divider(),
      _row(
        Icons.sync_rounded,
        'Pola',
        Text(
          schedule.repeat != null
              ? '${repeatDaysLabel(schedule.repeat!.days)}\n${repeatEndLabel(schedule.repeat!)}'
              : schedule.recurrence == 'weekly'
              ? 'Mingguan · ${schedule.repeatCount} pertemuan'
              : 'Satu pertemuan',
          style: _value,
        ),
      ),
      _divider(),
      _row(
        Icons.schedule_rounded,
        'Zona waktu',
        Text(AppTimezones.label(schedule.timezone), style: _value),
      ),
      _divider(),
      _row(
        Icons.bookmark_border_rounded,
        'Status seri',
        Align(
          alignment: Alignment.centerLeft,
          child: SessionStatusBadge(
            label: statusLabel(schedule.status),
            background: schedule.status == 'cancelled'
                ? SessionDetailStyle.paleRed
                : const Color(0xFFDEF2E6),
            foreground: schedule.status == 'cancelled'
                ? SessionDetailStyle.red
                : SessionDetailStyle.green,
          ),
        ),
      ),
      if (schedule.status == 'cancelled') ...[
        _divider(),
        const Text(
          'Alasan pembatalan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          schedule.cancellationReason ?? 'Alasan pembatalan belum dicatat.',
          style: _value,
        ),
      ],
    ],
  );

  static const _value = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 14,
    height: 1.45,
    color: SessionDetailStyle.ink,
  );
  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 9),
    child: Divider(height: 1, color: SessionDetailStyle.line),
  );
  Widget _row(IconData icon, String label, Widget value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: SessionDetailStyle.sage,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, size: 23, color: SessionDetailStyle.green),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: SessionDetailStyle.body.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 4),
              value,
            ],
          ),
        ),
      ),
    ],
  );
}

class ScheduleSeriesMeetingsTile extends StatelessWidget {
  final VoidCallback? onPressed;
  const ScheduleSeriesMeetingsTile({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) => Container(
    decoration: NalaraCardStyle.decoration(
      radius: 17,
      color: SessionDetailStyle.sage,
      borderColor: SessionDetailStyle.line,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDEFE3),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 24,
                  color: SessionDetailStyle.green,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lihat seluruh pertemuan',
                      style: TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 13.5,
                        height: 1.4,
                        color: SessionDetailStyle.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lihat dan kelola semua sesi dalam seri ini.',
                      style: SessionDetailStyle.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 23,
                color: SessionDetailStyle.green,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ScheduleSeriesWarning extends StatelessWidget {
  final bool cancelled;
  const ScheduleSeriesWarning({super.key, this.cancelled = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cancelled ? SessionDetailStyle.sage : const Color(0xFFFFEDEF),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 23,
          color: cancelled ? SessionDetailStyle.green : const Color(0xFFE73A54),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            cancelled
                ? 'Seri ini sudah dibatalkan. Riwayat pertemuan tetap tersedia.'
                : 'Semua sesi yang masih terjadwal dalam seri ini akan dibatalkan. Sesi yang sudah selesai tetap tersimpan.',
            style: SessionDetailStyle.body.copyWith(
              fontSize: 12.5,
              color: cancelled
                  ? SessionDetailStyle.green
                  : const Color(0xFFE73A54),
            ),
          ),
        ),
      ],
    ),
  );
}
