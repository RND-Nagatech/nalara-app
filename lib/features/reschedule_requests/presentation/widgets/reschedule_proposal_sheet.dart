import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/nalara_pickers.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../schedules/domain/entities/schedule_calendar.dart';
import '../../../schedules/domain/entities/schedule_period.dart';
import '../../domain/entities/reschedule_request.dart';
import '../../domain/repositories/reschedule_requests_repository.dart';
import 'reschedule_request_card.dart';

class RescheduleProposalSheet extends StatefulWidget {
  final RescheduleRequest request;
  final String timezone;
  final RescheduleRequestsRepository repository;
  final bool Function() isCurrent;

  const RescheduleProposalSheet({
    super.key,
    required this.request,
    required this.timezone,
    required this.repository,
    required this.isCurrent,
  });

  @override
  State<RescheduleProposalSheet> createState() =>
      _RescheduleProposalSheetState();
}

class _RescheduleProposalSheetState extends State<RescheduleProposalSheet> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  final _submit = SubmitCubit();
  late final LoadCubit<List<RescheduleSlot>> _slots;
  late DateTime _date;
  String? _selectedId;
  bool _pickingDate = false;

  bool get _current =>
      mounted &&
      widget.isCurrent() &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    final today = ScheduleCalendar.localDate(DateTime.now(), widget.timezone);
    final requested = ScheduleCalendar.localDate(
      widget.request.requestedStartAt,
      widget.timezone,
    );
    _date = requested.isBefore(today) ? today : requested;
    _slots = LoadCubit<List<RescheduleSlot>>(() {
      // A local-day query avoids truncating later dates at the API slot limit.
      final window = ScheduleCalendar.window(
        _date,
        SchedulePeriod.day,
        widget.timezone,
      );
      return widget.repository.availability(
        widget.request.id,
        from: window.from,
        to: window.until,
      );
    })..load();
  }

  @override
  void dispose() {
    _slots.close();
    _submit.close();
    _note.dispose();
    super.dispose();
  }

  RescheduleSlot? get _selectedSlot {
    for (final slot in _slots.state.value ?? <RescheduleSlot>[]) {
      if (slot.id == _selectedId) return slot;
    }
    return null;
  }

  Future<void> _pickDate() async {
    if (!_current || _submit.state.busy || _pickingDate) return;
    final today = ScheduleCalendar.localDate(DateTime.now(), widget.timezone);
    final initial = _date.isBefore(today) ? today : _date;
    setState(() => _pickingDate = true);
    DateTime? selected;
    try {
      selected = await showNalaraDatePicker(
        context: context,
        initialDate: DateTime(initial.year, initial.month, initial.day),
        firstDate: DateTime(today.year, today.month, today.day),
        lastDate: DateTime(2100, 12, 31),
      );
    } finally {
      if (mounted) setState(() => _pickingDate = false);
    }
    if (!mounted || selected == null || !_current) return;
    final date = ScheduleCalendar.date(selected);
    if (date == _date) return;
    setState(() {
      _date = date;
      _selectedId = null;
    });
    await _slots.load();
  }

  Future<void> _refreshSlots() async {
    if (_current && !_submit.state.busy) await _slots.load();
  }

  Future<void> _send() async {
    if (!_current ||
        _submit.state.busy ||
        _slots.state.status != LoadStatus.success ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final slot = _selectedSlot;
    if (slot == null) return;
    final ok = await _submit.run(
      () => widget.repository.review(
        widget.request.id,
        'proposed',
        proposedStartAt: slot.startAt,
        proposedEndAt: slot.endAt,
        note: _note.text.trim(),
      ),
    );
    if (!mounted) return;
    if (ok && _current) Navigator.of(context).pop(true);
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LoadCubit<List<RescheduleSlot>>, LoadState<List<RescheduleSlot>>>(
    bloc: _slots,
    builder: (context, slots) => BlocBuilder<SubmitCubit, SubmitState>(
      bloc: _submit,
      builder: (context, submit) => PopScope(
        canPop: !submit.busy,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tawarkan waktu lain',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih waktu tersedia (${widget.timezone}). '
                      'Sesi berubah setelah Orang Tua menerima tawaran.',
                      style: RescheduleRequestsStyle.body,
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      key: const ValueKey('reschedule-proposal-date'),
                      onPressed: submit.busy || _pickingDate ? null : _pickDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        'Tanggal: ${DateTimeUtils.date(DateTimeUtils.fromWallTime(_date, 0, 0, widget.timezone), widget.timezone)}',
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (slots.status == LoadStatus.loading)
                      const LinearProgressIndicator(),
                    if (slots.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          slots.error!,
                          key: const ValueKey(
                            'reschedule-proposal-slots-error',
                          ),
                          style: RescheduleRequestsStyle.body.copyWith(
                            color: RescheduleRequestsStyle.red,
                          ),
                        ),
                      ),
                    if (slots.status == LoadStatus.success &&
                        slots.value!.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Belum ada waktu tersedia pada tanggal ini. Pilih tanggal lain.',
                          style: RescheduleRequestsStyle.body,
                        ),
                      ),
                    NalaraDropdown<String>(
                      key: const ValueKey('reschedule-proposal-slot'),
                      value: _selectedId,
                      enabled:
                          !submit.busy &&
                          slots.status == LoadStatus.success &&
                          slots.value!.isNotEmpty,
                      hint: 'Pilih jam yang tersedia',
                      menuTitle: 'Pilih jam yang tersedia',
                      decoration: const InputDecoration(
                        labelText: 'Jam tersedia',
                      ),
                      options: [
                        for (final slot in slots.value ?? <RescheduleSlot>[])
                          NalaraDropdownOption(
                            value: slot.id,
                            label:
                                '${DateTimeUtils.time(slot.startAt, widget.timezone)} – ${DateTimeUtils.time(slot.endAt, widget.timezone)}',
                          ),
                      ],
                      onChanged: (value) => setState(() => _selectedId = value),
                      validator: (value) =>
                          value == null || _selectedSlot == null
                          ? 'Pilih jam yang tersedia'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const ValueKey(
                          'reschedule-proposal-slots-refresh',
                        ),
                        onPressed:
                            submit.busy || slots.status == LoadStatus.loading
                            ? null
                            : _refreshSlots,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Muat ulang pilihan waktu'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('reschedule-proposal-note'),
                      controller: _note,
                      enabled: !submit.busy,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Catatan untuk Orang Tua (opsional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (submit.error != null)
                      Text(
                        submit.error!,
                        key: const ValueKey('reschedule-proposal-error'),
                        style: RescheduleRequestsStyle.body.copyWith(
                          color: RescheduleRequestsStyle.red,
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('reschedule-proposal-send'),
                      onPressed:
                          submit.busy ||
                              _pickingDate ||
                              slots.status != LoadStatus.success ||
                              slots.value?.isNotEmpty != true
                          ? null
                          : _send,
                      child: submit.busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kirim tawaran waktu'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('reschedule-proposal-cancel'),
                      onPressed: submit.busy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
