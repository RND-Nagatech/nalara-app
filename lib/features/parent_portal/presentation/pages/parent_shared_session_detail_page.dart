import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../../utils/validators.dart';
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

    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          isDismissible: false,
          enableDrag: false,
          showDragHandle: true,
          backgroundColor: SessionDetailStyle.cream,
          builder: (context) => Theme(
            data: SessionDetailStyle.theme(Theme.of(context)),
            child: _ParentRescheduleSheet(
              data: data,
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
  final _submit = SubmitCubit();
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
    if (!_current || _submit.state.busy || _pickingDate) return;
    final today = ScheduleCalendar.localDate(DateTime.now(), _timezone);
    final initial = _date.isBefore(today) ? today : _date;
    setState(() => _pickingDate = true);
    DateTime? selected;
    try {
      selected = await showDatePicker(
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
      () => widget.repository.requestReschedule(
        widget.data.lesson.id,
        slot.startAt,
        slot.endAt,
        _reason.text.trim(),
      ),
    );
    if (!mounted) return;
    if (ok && _current) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<
        LoadCubit<List<ParentRescheduleSlot>>,
        LoadState<List<ParentRescheduleSlot>>
      >(
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
                          'Minta ganti tanggal',
                          style: SessionDetailStyle.title,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pilih tanggal dan jam yang tersedia ($_timezone). '
                          'Guru akan meninjau permintaan Anda.',
                          style: SessionDetailStyle.body,
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          key: const ValueKey('parent-reschedule-date'),
                          onPressed: submit.busy || _pickingDate
                              ? null
                              : _pickDate,
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(
                            'Tanggal: ${DateTimeUtils.date(DateTimeUtils.fromWallTime(_date, 0, 0, _timezone), _timezone)}',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _slotField(slots, submit.busy),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('parent-reschedule-reason'),
                          controller: _reason,
                          enabled: !submit.busy,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            labelText: 'Alasan perubahan jadwal',
                            hintText: 'Contoh: anak sedang sakit',
                            alignLabelWithHint: true,
                          ),
                          validator: Validators.requiredText,
                        ),
                        if (submit.error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            submit.error!,
                            key: const ValueKey('parent-reschedule-error'),
                            style: SessionDetailStyle.body.copyWith(
                              color: SessionDetailStyle.red,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const ValueKey('parent-reschedule-send'),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Kirim permintaan ke Guru'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          key: const ValueKey('parent-reschedule-cancel'),
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

  Widget _slotField(
    LoadState<List<ParentRescheduleSlot>> state,
    bool busy,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.status == LoadStatus.loading)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(),
        ),
      if (state.status == LoadStatus.error)
        Text(
          state.error!,
          key: const ValueKey('parent-reschedule-slots-error'),
          style: SessionDetailStyle.body.copyWith(
            color: SessionDetailStyle.red,
          ),
        ),
      if (state.status == LoadStatus.success && state.value!.isEmpty)
        const Text(
          'Belum ada slot yang tersedia pada tanggal ini. Pilih tanggal lain.',
          key: ValueKey('parent-reschedule-slots-empty'),
          style: SessionDetailStyle.body,
        ),
      NalaraDropdown<String>(
        key: const ValueKey('parent-reschedule-slot'),
        value: _slotId,
        enabled: !busy && state.status == LoadStatus.success,
        menuTitle: 'Pilih jam yang tersedia',
        hint: 'Pilih jam yang tersedia',
        decoration: const InputDecoration(labelText: 'Jam tersedia'),
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
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          key: const ValueKey('parent-reschedule-slots-refresh'),
          onPressed: busy || state.status == LoadStatus.loading
              ? null
              : _refreshSlots,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Muat ulang pilihan waktu'),
        ),
      ),
    ],
  );
}
