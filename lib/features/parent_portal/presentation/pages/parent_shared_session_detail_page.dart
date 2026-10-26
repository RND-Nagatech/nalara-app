import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/nalara_pickers.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../../utils/validators.dart';
import '../../../../utils/color.dart';
import '../../../reschedule_requests/presentation/bloc/reschedule_submission_cubit.dart';
import '../../../reschedule_requests/presentation/widgets/reschedule_form_sheet.dart';
import '../../../schedules/domain/entities/schedule_calendar.dart';
import '../../../schedules/domain/entities/schedule_period.dart';
import '../../../schedules/domain/entities/session_overview.dart';
import '../../../schedules/presentation/pages/session_detail_page.dart';
import '../../../schedules/presentation/widgets/session_detail_style.dart';
import '../../domain/entities/parent_portal.dart';
import '../../domain/repositories/parent_portal_repository.dart';

/// Shares teacher session cards using an authorized parent overview loader.
///
/// The loader must return the real schedule and server-scoped session reports.
class ParentSharedSessionDetailPage extends StatelessWidget {
  final String id;
  final SessionOverviewLoader loadOverview;

  const ParentSharedSessionDetailPage({
    super.key,
    required this.id,
    required this.loadOverview,
  });

  Future<bool> _request(BuildContext context, SessionOverview data) async {
    final expectedPath =
        '/parent/sessions/${Uri.encodeComponent(data.lesson.id)}';
    bool current() {
      if (!context.mounted) return false;
      final router = GoRouter.maybeOf(context);
      return router == null || router.state.uri.path == expectedPath;
    }

    // A request may have been submitted on another device since this page loaded.
    final latest = await loadOverview(data.lesson.id);
    if (!context.mounted || !current()) return false;
    if (latest.reschedulePending == true) return true;

    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          isDismissible: false,
          enableDrag: false,
          showDragHandle: true,
          backgroundColor: SessionDetailStyle.cream,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => Theme(
            data: SessionDetailStyle.theme(Theme.of(context)),
            child: _ParentRescheduleSheet(
              data: latest,
              repository: getIt<ParentPortalRepository>(),
              isCurrent: current,
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) => SessionDetailPage(
    id: id,
    loadOverview: loadOverview,
    readOnly: true,
    routePrefix: '/parent',
    // The parent portal currently has no series-detail route.
    allowSeriesNavigation: false,
    onRequestReschedule: _request,
  );
}

class _ParentRescheduleSheet extends StatefulWidget {
  final SessionOverview data;
  final ParentPortalRepository repository;
  final bool Function() isCurrent;

  const _ParentRescheduleSheet({
    required this.data,
    required this.repository,
    required this.isCurrent,
  });

  @override
  State<_ParentRescheduleSheet> createState() => _ParentRescheduleSheetState();
}

class _ParentRescheduleSheetState extends State<_ParentRescheduleSheet> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _submit = RescheduleSubmissionCubit();
  late final LoadCubit<List<ParentRescheduleSlot>> _slots;
  late DateTime _date;
  String? _slotId;
  bool _pickingDate = false;

  String get _timezone => widget.data.schedule.timezone;
  bool get _current =>
      mounted &&
      widget.isCurrent() &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    _date = ScheduleCalendar.localDate(DateTime.now(), _timezone);
    _slots = LoadCubit<List<ParentRescheduleSlot>>(() {
      // Fetch one chosen local day so the server's slot limit cannot hide
      // later dates in a month-wide response. Every option comes from the API.
      final window = ScheduleCalendar.window(
        _date,
        SchedulePeriod.day,
        _timezone,
      );
      return widget.repository.availability(
        widget.data.lesson.id,
        window.from,
        window.until,
      );
    })..load();
  }

  @override
  void dispose() {
    _slots.close();
    _submit.close();
    _reason.dispose();
    super.dispose();
  }

  String _id(ParentRescheduleSlot slot) =>
      '${slot.startAt.toUtc().toIso8601String()}/${slot.endAt.toUtc().toIso8601String()}';

  ParentRescheduleSlot? get _selectedSlot {
    for (final slot in _slots.state.value ?? <ParentRescheduleSlot>[]) {
      if (_id(slot) == _slotId) return slot;
    }
    return null;
  }

  Future<void> _pickDate() async {
    if (!_current || _submit.state.locked || _pickingDate) return;
    final today = ScheduleCalendar.localDate(DateTime.now(), _timezone);
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
    if (selected == null || !_current) return;
    final date = ScheduleCalendar.date(selected);
    if (date == _date) return;
    setState(() {
      _date = date;
      _slotId = null;
    });
    await _slots.load();
  }

  Future<void> _refreshSlots() async {
    if (_current && !_submit.state.locked) await _slots.load();
  }

  Future<void> _send() async {
    if (!_current ||
        _submit.state.locked ||
        _slots.state.status != LoadStatus.success ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final slot = _selectedSlot;
    if (slot == null) return;
    final ok = await _submit.send(
      () => widget.repository.requestReschedule(
        widget.data.lesson.id,
        slot.startAt,
        slot.endAt,
        _reason.text.trim(),
      ),
      () async =>
          (await widget.repository.sessionOverview(
            widget.data.lesson.id,
          )).reschedulePending ==
          true,
    );
    if (!mounted || !ok) return;
    // Let PopScope rebuild to the non-busy state before popping this sheet.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (_current) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<
        LoadCubit<List<ParentRescheduleSlot>>,
        LoadState<List<ParentRescheduleSlot>>
      >(
        bloc: _slots,
        builder: (context, slots) =>
            BlocBuilder<RescheduleSubmissionCubit, RescheduleSubmissionState>(
              bloc: _submit,
              builder: (context, submit) => PopScope(
                canPop: !submit.busy,
                child: RescheduleFormSheet(
                  title: 'Ubah jadwal les',
                  description:
                      'Pilih waktu pengganti untuk ${widget.data.lesson.studentName.isEmpty ? 'sesi ini' : widget.data.lesson.studentName}. Zona waktu: $_timezone.',
                  closeKey: const ValueKey('parent-reschedule-cancel'),
                  onClose: submit.busy
                      ? null
                      : () => Navigator.of(context).pop(submit.waiting),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Tanggal baru',
                          style: RescheduleFormSheet.labelStyle,
                        ),
                        const SizedBox(height: 7),
                        OutlinedButton(
                          key: const ValueKey('parent-reschedule-date'),
                          onPressed: submit.locked || _pickingDate
                              ? null
                              : _pickDate,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: NalaraColors.field,
                            foregroundColor: NalaraColors.ink,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: NalaraColors.line),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateTimeUtils.date(
                                    DateTimeUtils.fromWallTime(
                                      _date,
                                      0,
                                      0,
                                      _timezone,
                                    ),
                                    _timezone,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.expand_more_rounded,
                                size: 20,
                                color: NalaraColors.muted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _slotField(slots, submit.locked),
                        const SizedBox(height: 16),
                        const Text(
                          'Alasan perubahan',
                          style: RescheduleFormSheet.labelStyle,
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          key: const ValueKey('parent-reschedule-reason'),
                          controller: _reason,
                          enabled: !submit.locked,
                          minLines: 2,
                          maxLines: 4,
                          maxLength: 500,
                          style: SessionDetailStyle.body.copyWith(
                            color: NalaraColors.ink,
                          ),
                          decoration: RescheduleFormSheet.input(
                            'Contoh: anak sedang sakit',
                          ),
                          validator: Validators.requiredText,
                        ),
                        if (submit.error != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            submit.error!,
                            key: const ValueKey('parent-reschedule-error'),
                            style: SessionDetailStyle.body.copyWith(
                              color: NalaraColors.danger,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Jadwal awal tetap berlaku sampai Guru menyetujui perubahan.',
                          style: SessionDetailStyle.body,
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          key: const ValueKey('parent-reschedule-send'),
                          onPressed:
                              submit.locked ||
                                  _pickingDate ||
                                  slots.status != LoadStatus.success ||
                                  _selectedSlot == null
                              ? null
                              : _send,
                          style: FilledButton.styleFrom(
                            backgroundColor: NalaraColors.green,
                            minimumSize: const Size(48, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: submit.busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  submit.waiting
                                      ? 'Menunggu tanggapan Guru'
                                      : 'Kirim permintaan ke Guru',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      );

  Widget _slotField(
    LoadState<List<ParentRescheduleSlot>> state,
    bool locked,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text('Jam tersedia', style: RescheduleFormSheet.labelStyle),
          ),
          IconButton(
            key: const ValueKey('parent-reschedule-slots-refresh'),
            tooltip: 'Muat ulang pilihan waktu',
            onPressed: locked || state.status == LoadStatus.loading
                ? null
                : _refreshSlots,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            style: IconButton.styleFrom(foregroundColor: NalaraColors.green),
          ),
        ],
      ),
      if (state.status == LoadStatus.loading)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: LinearProgressIndicator(minHeight: 2),
        ),
      if (state.status == LoadStatus.error)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            state.error!,
            key: const ValueKey('parent-reschedule-slots-error'),
            style: SessionDetailStyle.body.copyWith(color: NalaraColors.danger),
          ),
        ),
      if (state.status == LoadStatus.success && state.value!.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Tidak ada waktu tersedia. Coba tanggal lain.',
            key: ValueKey('parent-reschedule-slots-empty'),
            style: SessionDetailStyle.body,
          ),
        ),
      NalaraDropdown<String>(
        key: const ValueKey('parent-reschedule-slot'),
        value: _slotId,
        enabled:
            !locked &&
            state.status == LoadStatus.success &&
            state.value?.isNotEmpty == true,
        menuTitle: 'Pilih jam yang tersedia',
        hint: 'Pilih jam yang tersedia',
        decoration: RescheduleFormSheet.input('Pilih jam yang tersedia'),
        options: [
          for (final slot in state.value ?? <ParentRescheduleSlot>[])
            NalaraDropdownOption(
              value: _id(slot),
              label:
                  '${DateTimeUtils.time(slot.startAt, _timezone)} – ${DateTimeUtils.time(slot.endAt, _timezone)}',
            ),
        ],
        onChanged: (value) => setState(() => _slotId = value),
        validator: (value) => value == null || _selectedSlot == null
            ? 'Pilih jam yang tersedia'
            : null,
      ),
    ],
  );
}
