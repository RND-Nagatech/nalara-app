import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/schedule_calendar.dart';
import '../../domain/entities/schedule_period.dart';
import 'agenda_style.dart';

class AgendaCalendar extends StatelessWidget {
  final DateTime date;
  final SchedulePeriod period;
  final VoidCallback? onPrevious, onNext;
  final VoidCallback onPick;
  final ValueChanged<DateTime> onDay;
  const AgendaCalendar({
    super.key,
    required this.date,
    required this.period,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    required this.onDay,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
    child: Column(
      children: [
        Row(
          children: [
            _arrow(
              'agenda-previous-${period.name}',
              'Periode sebelumnya',
              Icons.chevron_left_rounded,
              onPrevious,
            ),
            Expanded(
              child: TextButton(
                key: ValueKey('agenda-caption-${period.name}'),
                onPressed: onPick,
                child: Text(
                  AgendaStyle.caption(date, period),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: AgendaStyle.green,
                  ),
                ),
              ),
            ),
            _arrow(
              'agenda-next-${period.name}',
              'Periode berikutnya',
              Icons.chevron_right_rounded,
              onNext,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            final cellWidth = math.max(
              constraints.maxWidth / 7,
              scaler.scale(12) * 2.8 + 8,
            );
            final circle = math.max(40.0, scaler.scale(16) * 1.4 + 12);
            final cells = ScheduleCalendar.monthCells(date);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: cellWidth * 7,
                child: period == SchedulePeriod.month
                    ? Column(
                        key: const ValueKey('agenda-month-grid'),
                        children: [
                          Row(
                            children: [
                              for (final label in AgendaStyle.weekdays)
                                SizedBox(
                                  width: cellWidth,
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'NalaraInter',
                                      fontSize: 12,
                                      height: 1.4,
                                      color: AgendaStyle.muted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          for (var row = 0; row < cells.length ~/ 7; row++)
                            Row(
                              children: [
                                for (var column = 0; column < 7; column++)
                                  if (cells[row * 7 + column] case final day?)
                                    _day(day, cellWidth, circle, false)
                                  else
                                    SizedBox(
                                      width: cellWidth,
                                      height: circle + 8,
                                    ),
                              ],
                            ),
                        ],
                      )
                    : Row(
                        key: ValueKey('agenda-week-strip-${period.name}'),
                        children: [
                          for (final day in ScheduleCalendar.weekDays(date))
                            _day(day, cellWidth, circle, true),
                        ],
                      ),
              ),
            );
          },
        ),
      ],
    ),
  );
  Widget _arrow(
    String key,
    String tooltip,
    IconData icon,
    VoidCallback? onTap,
  ) => IconButton(
    key: ValueKey(key),
    onPressed: onTap,
    tooltip: tooltip,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xFFE6EFE3),
      foregroundColor: AgendaStyle.green,
      fixedSize: const Size(36, 36),
    ),
    icon: Icon(icon, size: 25),
  );
  Widget _day(DateTime day, double width, double circle, bool weekday) {
    final selected = day == ScheduleCalendar.date(date);
    final inWeek = period == SchedulePeriod.week;
    final enabled = ScheduleCalendar.allowed(day);
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            if (weekday) ...[
              Text(
                AgendaStyle.weekdays[day.weekday - 1],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 12,
                  height: 1.4,
                  color: selected || inWeek
                      ? AgendaStyle.green
                      : AgendaStyle.muted,
                ),
              ),
              const SizedBox(height: 7),
            ],
            Semantics(
              selected: selected,
              button: true,
              enabled: enabled,
              label: AgendaStyle.dayLabel(day),
              child: Material(
                color: selected
                    ? AgendaStyle.green
                    : inWeek
                    ? const Color(0xFFE7EFE3)
                    : Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  key: ValueKey(
                    'agenda-day-${period.name}-${day.toIso8601String()}',
                  ),
                  customBorder: const CircleBorder(),
                  onTap: enabled ? () => onDay(day) : null,
                  child: SizedBox(
                    width: circle,
                    height: circle,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 16,
                          height: 1.2,
                          color: selected
                              ? Colors.white
                              : enabled
                              ? AgendaStyle.ink
                              : AgendaStyle.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
