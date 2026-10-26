import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/nalara_pickers.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/schedule_repeat.dart';
import '../bloc/schedule_repeat_cubit.dart';
import 'schedule_form_fields.dart';
import 'schedule_form_style.dart';

const repeatDayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const _shortDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
String repeatEndLabel(ScheduleRepeat repeat) => switch (repeat.end) {
  ScheduleRepeatEnd.never => 'Sampai dihentikan',
  ScheduleRepeatEnd.count => '${repeat.count} pertemuan',
  ScheduleRepeatEnd.until =>
    repeat.until == null
        ? 'Pilih tanggal akhir'
        : 'Sampai ${DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(repeat.until!))}',
};
String repeatDaysLabel(Set<int> days) => days.length == 7
    ? 'Setiap hari'
    : 'Setiap ${(days.toList()..sort()).map((day) => repeatDayNames[day - 1]).join(', ')}';

class ScheduleRepeatFields extends StatefulWidget {
  final ScheduleRepeatCubit cubit;
  final DateTime start, end;
  final String timezone;
  final bool enabled, showToggle;
  final String? studentsLabel;
  const ScheduleRepeatFields({
    super.key,
    required this.cubit,
    required this.start,
    required this.end,
    required this.timezone,
    this.enabled = true,
    this.showToggle = true,
    this.studentsLabel,
  });
  @override
  State<ScheduleRepeatFields> createState() => _ScheduleRepeatFieldsState();
}

class _ScheduleRepeatFieldsState extends State<ScheduleRepeatFields> {
  late final _count = TextEditingController(
    text: widget.cubit.state.value.count.toString(),
  );
  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  String get _startDate {
    final local = DateTimeUtils.local(widget.start, widget.timezone);
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickUntil() async {
    final local = DateTimeUtils.local(widget.start, widget.timezone);
    final first = DateTime(local.year, local.month, local.day);
    final last = DateTime(first.year, first.month, first.day + 366);
    final value =
        DateTime.tryParse(widget.cubit.state.value.until ?? '') ?? first;
    final picked = await showNalaraDatePicker(
      context: context,
      initialDate: value.isBefore(first)
          ? first
          : value.isAfter(last)
          ? last
          : value,
      firstDate: first,
      lastDate: last,
      helpText: 'Ulangi sampai tanggal',
    );
    if (!mounted || picked == null) return;
    widget.cubit.until(
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ScheduleRepeatCubit, ScheduleRepeatState>(
    bloc: widget.cubit,
    builder: (context, state) => ScheduleFormSection(
      label: 'Pengulangan jadwal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showToggle)
            Semantics(
              toggled: state.enabled,
              button: true,
              label: 'Ulangi jadwal',
              child: InkWell(
                key: const ValueKey('schedule-repeat-toggle'),
                borderRadius: BorderRadius.circular(12),
                onTap: widget.enabled
                    ? () => widget.cubit.enable(!state.enabled)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ulangi setiap minggu',
                          style: ScheduleFormStyle.label,
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 48,
                        height: 28,
                        padding: const EdgeInsets.all(3),
                        alignment: state.enabled
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: state.enabled
                              ? ScheduleFormStyle.green
                              : ScheduleFormStyle.line,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!state.enabled)
            const Text(
              'Nonaktif: jadwal dibuat satu kali saja.',
              style: ScheduleFormStyle.supporting,
            ),
          if (state.enabled) ...[
            const SizedBox(height: 12),
            const Text('Pilih hari', style: ScheduleFormStyle.supporting),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (int day = 1; day <= 7; day++)
                  Semantics(
                    button: true,
                    selected: state.value.days.contains(day),
                    label: repeatDayNames[day - 1],
                    child: Material(
                      color: state.value.days.contains(day)
                          ? ScheduleFormStyle.green
                          : ScheduleFormStyle.paleGreen,
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        key: ValueKey('schedule-repeat-day-$day'),
                        borderRadius: BorderRadius.circular(13),
                        onTap: widget.enabled
                            ? () => widget.cubit.toggleDay(day)
                            : null,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 44,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 12,
                            ),
                            child: Text(
                              _shortDays[day - 1],
                              textAlign: TextAlign.center,
                              style: ScheduleFormStyle.label.copyWith(
                                fontSize: 12,
                                color: state.value.days.contains(day)
                                    ? Colors.white
                                    : ScheduleFormStyle.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            NalaraDropdown<ScheduleRepeatEnd>(
              key: const ValueKey('schedule-repeat-end'),
              value: state.value.end,
              enabled: widget.enabled,
              menuTitle: 'Akhir pengulangan',
              options: const [
                NalaraDropdownOption(
                  value: ScheduleRepeatEnd.never,
                  label: 'Sampai dihentikan',
                ),
                NalaraDropdownOption(
                  value: ScheduleRepeatEnd.until,
                  label: 'Tanggal tertentu',
                ),
                NalaraDropdownOption(
                  value: ScheduleRepeatEnd.count,
                  label: 'Sejumlah pertemuan',
                ),
              ],
              onChanged: (value) {
                if (value != null) widget.cubit.changeEnd(value);
              },
            ),
            if (state.value.end == ScheduleRepeatEnd.count) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('schedule-repeat-count'),
                controller: _count,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah pertemuan',
                  helperText: 'Total 1–52 pertemuan, bukan jumlah minggu',
                ),
                onChanged: (text) =>
                    widget.cubit.count(int.tryParse(text) ?? 0),
              ),
            ],
            if (state.value.end == ScheduleRepeatEnd.until) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const ValueKey('schedule-repeat-until'),
                onPressed: widget.enabled ? _pickUntil : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text(
                    state.value.until == null
                        ? 'Pilih tanggal akhir'
                        : repeatEndLabel(state.value),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1, color: ScheduleFormStyle.line),
            const SizedBox(height: 12),
            Text(
              state.value.days.isEmpty
                  ? 'Belum ada hari yang dipilih'
                  : repeatDaysLabel(state.value.days),
              style: ScheduleFormStyle.label,
            ),
            const SizedBox(height: 5),
            Text(
              '${DateTimeUtils.time(widget.start, widget.timezone)}–${DateTimeUtils.time(widget.end, widget.timezone)} · Mulai ${DateTimeUtils.date(widget.start, widget.timezone)}',
              style: ScheduleFormStyle.supporting,
            ),
            if (widget.studentsLabel != null)
              Text(widget.studentsLabel!, style: ScheduleFormStyle.supporting),
            Text(
              repeatEndLabel(state.value),
              style: ScheduleFormStyle.supporting,
            ),
            ...[
              const SizedBox(height: 8),
              const Text(
                'Pertemuan disiapkan bertahap hingga 8 minggu ke depan sesuai batas yang dipilih. Kelanjutannya otomatis selama Pro/Trial aktif.',
                style: ScheduleFormStyle.supporting,
              ),
            ],
            if (widget.cubit.validate(_startDate) != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.cubit.validate(_startDate)!,
                style: ScheduleFormStyle.supporting.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ],
      ),
    ),
  );
}
