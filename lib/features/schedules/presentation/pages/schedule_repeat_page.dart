import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_repeat.dart';
import '../../domain/repositories/schedules_repository.dart';
import '../../domain/repositories/schedule_repeat_repository.dart';
import '../bloc/schedule_repeat_cubit.dart';
import '../widgets/schedule_form_fields.dart';
import '../widgets/schedule_form_style.dart';
import '../widgets/schedule_repeat_fields.dart';

class ScheduleRepeatPage extends StatelessWidget {
  final String id;
  const ScheduleRepeatPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => AsyncPage<Schedule>(
    title: 'Pengulangan jadwal',
    load: () => getIt<SchedulesRepository>().schedule(id),
    builder: (context, schedule, _) =>
        _RepeatEditor(key: ValueKey(schedule.id), schedule: schedule),
  );
}

class _RepeatEditor extends StatefulWidget {
  final Schedule schedule;
  const _RepeatEditor({super.key, required this.schedule});
  @override
  State<_RepeatEditor> createState() => _RepeatEditorState();
}

class _RepeatEditorState extends State<_RepeatEditor> {
  late DateTime start =
      widget.schedule.nextStartAt ??
      DateTime.now().toUtc().add(const Duration(hours: 1));
  late DateTime end =
      widget.schedule.nextEndAt ??
      start.add(widget.schedule.endAt.difference(widget.schedule.startAt));
  late final repeat = ScheduleRepeatCubit(
    initial:
        widget.schedule.repeat ??
        ScheduleRepeat(
          days: {DateTimeUtils.local(start, widget.schedule.timezone).weekday},
          end: widget.schedule.recurrence == 'weekly'
              ? ScheduleRepeatEnd.count
              : ScheduleRepeatEnd.never,
          count: widget.schedule.repeatCount,
        ),
  );
  final submit = SubmitCubit();
  @override
  void dispose() {
    repeat.close();
    submit.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (submit.state.busy) return;
    final local = DateTimeUtils.local(start, widget.schedule.timezone);
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final error = repeat.validate(date);
    if (error != null || !end.isAfter(start)) {
      errorMessage(context, error ?? 'Waktu selesai harus setelah mulai');
      return;
    }
    Schedule? result;
    final ok = await submit.run(() async {
      result = await getIt<ScheduleRepeatRepository>().changeRepeat(
        widget.schedule.id,
        start,
        end,
        widget.schedule.timezone,
        repeat.state.value,
      );
    });
    if (!mounted || !ok || result == null) return;
    successMessage(
      context,
      'Pengulangan diperbarui. Riwayat lama tetap tersimpan.',
    );
    context.go('/teacher/schedule/${result!.id}');
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ScheduleFormStyle.theme(Theme.of(context)),
    child: BlocBuilder<SubmitCubit, SubmitState>(
      bloc: submit,
      builder: (context, state) => PageBody(
        children: [
          const Text('Ubah jadwal berikutnya', style: ScheduleFormStyle.label),
          const SizedBox(height: 8),
          Text(
            '${widget.schedule.participantCount} siswa tetap terpilih. Pola baru berlaku mulai pertemuan berikutnya; pertemuan yang sudah selesai tidak berubah.',
            style: ScheduleFormStyle.supporting,
          ),
          const SizedBox(height: 18),
          ScheduleDateTimeCard(
            label: 'Mulai pola baru',
            value: start,
            timezone: widget.schedule.timezone,
            enabled: !state.busy,
            onChanged: (value) => setState(() {
              final duration = end.difference(start);
              start = value;
              end = start.add(duration);
            }),
          ),
          ScheduleDateTimeCard(
            label: 'Selesai',
            value: end,
            timezone: widget.schedule.timezone,
            enabled: !state.busy,
            onChanged: (value) => setState(() => end = value),
          ),
          ScheduleRepeatFields(
            cubit: repeat,
            start: start,
            end: end,
            timezone: widget.schedule.timezone,
            enabled: !state.busy,
            showToggle: false,
          ),
          SubmitButton(
            cubit: submit,
            label: 'Simpan pengulangan',
            onPressed: _save,
          ),
        ],
      ),
    ),
  );
}
