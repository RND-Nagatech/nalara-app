import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../../shared/domain/app_timezones.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../teaching_guide/presentation/teaching_tutorial_scope.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/schedules_repository.dart';
import '../../domain/usecases/load_teaching_options.dart';
import '../../domain/usecases/load_schedule_options.dart';
import '../widgets/schedule_form_fields.dart';
import '../widgets/schedule_form_header.dart';
import '../widgets/schedule_form_style.dart';
import '../widgets/schedule_prerequisites.dart';
import '../widgets/schedule_repeat_fields.dart';
import '../widgets/schedule_timezone_info.dart';
import '../bloc/schedule_repeat_cubit.dart';
import '../../domain/repositories/schedule_repeat_repository.dart';
import '../../domain/usecases/load_reschedule.dart';
import 'schedule_agenda_page.dart';

export 'session_detail_page.dart';
export 'schedule_detail_page.dart';

class SchedulesPage extends StatelessWidget {
  final bool attendance;
  final DateTime? initialDate;
  final String? initialPeriod;
  final String? timezone;
  const SchedulesPage({
    super.key,
    this.attendance = false,
    this.initialDate,
    this.initialPeriod,
    this.timezone,
  });
  @override
  Widget build(BuildContext context) {
    if (timezone != null || !getIt.isRegistered<AuthCubit>()) {
      return _agenda(timezone ?? AppTimezones.jakarta);
    }
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      buildWhen: (previous, current) =>
          previous.teacher?.timezone != current.teacher?.timezone,
      builder: (context, state) =>
          _agenda(state.teacher?.timezone ?? AppTimezones.jakarta),
    );
  }

  Widget _agenda(String timezone) => ScheduleAgendaPage(
    initialDate: initialDate,
    initialPeriod: initialPeriod ?? (attendance ? 'week' : 'day'),
    timezone: timezone,
    attendance: attendance,
  );
}

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  final String timezone;
  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
    this.timezone = 'Asia/Jakarta',
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: NalaraSurfaceCard(
      key: ValueKey(lesson.id),
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EFE5),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.event_outlined,
              color: Color(0xFF155A49),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.studentName.isEmpty
                      ? 'Sesi les'
                      : '${lesson.studentName} · ${lesson.subjectName}',
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E292D),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${DateTimeUtils.full(lesson.startAt, timezone)} – ${DateTimeUtils.time(lesson.endAt, timezone)}',
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 12.5,
                    height: 1.45,
                    color: Color(0xFF7B7F80),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${statusLabel(lesson.status)} · Presensi: ${statusLabel(lesson.attendance)}',
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 11.5,
                    height: 1.4,
                    color: Color(0xFF155A49),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF1E292D),
            size: 24,
          ),
        ],
      ),
    ),
  );
}

class ScheduleFormPage extends StatefulWidget {
  final String? studentId, groupId;
  const ScheduleFormPage({super.key, this.studentId, this.groupId});

  @override
  State<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends State<ScheduleFormPage>
    with TeachingCatalogRefresh<ScheduleFormPage> {
  late final _loader = LoadCubit<TeachingOptions>(
    getIt<LoadScheduleOptions>().call,
  )..load();
  bool _openingTimezoneSettings = false;

  @override
  void onTeachingCatalogChanged() => _loader.load();

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) await _loader.load();
  }

  Future<void> _openTimezoneSettings() async {
    if (_openingTimezoneSettings) return;
    _openingTimezoneSettings = true;
    FocusScope.of(context).unfocus();
    try {
      await context.push('/teacher/settings');
    } finally {
      _openingTimezoneSettings = false;
    }
  }

  Widget _editor(TeachingOptions options, String? error) {
    Widget buildEditor(AuthState? account) => _ScheduleEditor(
      // A confirmed timezone change must not replace the form's draft state.
      key: ValueKey((
        account?.teacher?.id,
        account?.teacher?.workspaceId,
        widget.studentId,
        widget.groupId,
      )),
      options: options,
      timezone: account?.teacher?.timezone ?? AppTimezones.jakarta,
      studentId: widget.studentId,
      groupId: widget.groupId,
      catalogError: error,
      manageGroups: () => _open('/teacher/student-groups'),
      onTimezoneSettings: _openTimezoneSettings,
    );

    if (!getIt.isRegistered<AuthCubit>()) return buildEditor(null);
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      buildWhen: (previous, current) =>
          previous.teacher?.id != current.teacher?.id ||
          previous.teacher?.workspaceId != current.teacher?.workspaceId ||
          previous.teacher?.timezone != current.teacher?.timezone,
      builder: (_, account) => buildEditor(account),
    );
  }

  @override
  void dispose() {
    _loader.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: ScheduleFormStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: ScheduleFormStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child:
                  BlocBuilder<
                    LoadCubit<TeachingOptions>,
                    LoadState<TeachingOptions>
                  >(
                    bloc: _loader,
                    builder: (context, state) {
                      if (state.status == LoadStatus.error &&
                          state.value == null) {
                        return _withHeader(
                          ErrorNotice(state.error!, retry: _loader.load),
                        );
                      }
                      final options = state.value;
                      if (options == null) {
                        return _withHeader(
                          const Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (options.students.isEmpty ||
                          options.subjects.isEmpty) {
                        return _withHeader(
                          RefreshIndicator(
                            onRefresh: _loader.load,
                            child: SchedulePrerequisites(
                              onAddStudent: () =>
                                  _open('/teacher/students/new'),
                              onAddSubject: () =>
                                  _open('/teacher/subjects/new'),
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _loader.load,
                        child: _editor(options, state.error),
                      );
                    },
                  ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _withHeader(Widget body) => Column(
    children: [
      NalaraHeader(
        child: ScheduleFormHeader(
          onBack: () => finishForm(context, '/teacher/schedule'),
        ),
      ),
      Expanded(child: body),
    ],
  );
}

class _ScheduleEditor extends StatefulWidget {
  final TeachingOptions options;
  final String timezone;
  final String? studentId, groupId;
  final String? catalogError;
  final Future<void> Function() manageGroups;
  final Future<void> Function() onTimezoneSettings;
  const _ScheduleEditor({
    super.key,
    required this.options,
    required this.timezone,
    this.studentId,
    this.groupId,
    this.catalogError,
    required this.manageGroups,
    required this.onTimezoneSettings,
  });
  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  final form = GlobalKey<FormState>(), submit = SubmitCubit();
  String? _selectedGroupId, _groupNotice;
  late Set<String> studentIds = {
    if (widget.options.students.any((s) => s.id == widget.studentId))
      widget.studentId!,
  };
  late String subjectId = widget.options.subjects.first.id;
  String get timezone => widget.timezone;
  DateTime start = DateTime.now().toUtc().add(const Duration(hours: 1)),
      end = DateTime.now().toUtc().add(const Duration(hours: 2));
  late final repeat = ScheduleRepeatCubit(
    weekday: DateTimeUtils.local(start, timezone).weekday,
  );
  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) _selectGroup(widget.groupId!);
  }

  @override
  void didUpdateWidget(covariant _ScheduleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timezone != widget.timezone) {
      // Keep the chosen UTC instants/duration. Only display and the automatic
      // repeat day follow the newly confirmed account zone.
      repeat.anchorChanged(DateTimeUtils.local(start, timezone).weekday);
    }
  }

  void _selectGroup(String id) {
    if (id.isEmpty) {
      _selectedGroupId = null;
      _groupNotice = null;
      return;
    }
    final group = widget.options.groups.where((g) => g.id == id).firstOrNull;
    if (group == null) {
      _groupNotice =
          'Grup ini tidak tersedia. Pilih grup lain atau pilih siswa secara manual.';
      return;
    }
    _selectedGroupId = id;
    studentIds = group.activeMemberIds(widget.options.students);
    final skipped = group.studentIds.length - studentIds.length;
    _groupNotice = studentIds.isEmpty
        ? 'Belum ada anggota aktif pada grup ini. Pilih siswa atau perbarui grup.'
        : skipped > 0
        ? '${studentIds.length} siswa aktif dipilih. $skipped anggota tidak aktif/tidak tersedia dilewati.'
        : '${studentIds.length} anggota grup dipilih. Anda masih bisa menyesuaikan pilihan siswa.';
  }

  @override
  void dispose() {
    repeat.close();
    submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: submit,
    builder: (context, state) => Form(
      key: form,
      child: NalaraPageLayout(
        header: ScheduleFormHeader(
          onBack: state.busy
              ? null
              : () => finishForm(context, '/teacher/schedule'),
        ),
        body: ListView(
          key: const ValueKey('schedule-form-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const ScheduleFormHeader(showIntro: true, onBack: null),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.catalogError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Pilihan belum dapat diperbarui. Isian Anda tetap disimpan. ${widget.catalogError}',
                        style: ScheduleFormStyle.supporting,
                      ),
                    ),
                  ScheduleFormSection(
                    label: 'Grup siswa (opsional)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NalaraDropdown<String>(
                          key: const ValueKey('schedule-student-group'),
                          value: _selectedGroupId ?? '',
                          enabled: !state.busy,
                          menuTitle: 'Pilih grup siswa',
                          searchHint: 'Cari grup...',
                          options: [
                            const NalaraDropdownOption(
                              value: '',
                              label: 'Pilih siswa secara manual',
                            ),
                            for (final group in widget.options.groups)
                              NalaraDropdownOption(
                                value: group.id,
                                label:
                                    '${group.name} · ${group.studentIds.length} siswa',
                              ),
                            if (_selectedGroupId != null &&
                                !widget.options.groups.any(
                                  (g) => g.id == _selectedGroupId,
                                ))
                              NalaraDropdownOption(
                                value: _selectedGroupId!,
                                label: 'Grup tidak lagi tersedia',
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectGroup(value));
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _groupNotice ??
                              'Memilih grup mengganti pilihan siswa dengan anggota aktif grup tersebut.',
                          style: ScheduleFormStyle.supporting,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: state.busy ? null : widget.manageGroups,
                            child: Text(
                              widget.options.groups.isEmpty
                                  ? 'Buat grup siswa'
                                  : 'Kelola grup siswa',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScheduleFormSection(
                    label: 'Siswa',
                    child: TutorialTarget(
                      id: 'form-schedule',
                      child: NalaraMultiDropdown<String>(
                        key: const ValueKey('schedule-student'),
                        selectedValues: studentIds,
                        enabled: !state.busy,
                        menuTitle: 'Pilih siswa',
                        searchHint: 'Cari siswa...',
                        hint: 'Pilih satu atau beberapa siswa',
                        validator: (values) {
                          if (values == null || values.isEmpty) {
                            return 'Pilih minimal satu siswa';
                          }
                          if (values.length > 100) {
                            return 'Maksimal 100 siswa per jadwal';
                          }
                          if (values.any(
                            (id) =>
                                !widget.options.students.any((s) => s.id == id),
                          )) {
                            return 'Pilihan siswa tidak lagi tersedia. Periksa kembali.';
                          }
                          return null;
                        },
                        options: [
                          ...widget.options.students.map(
                            (s) => NalaraDropdownOption(
                              value: s.id,
                              label: s.name,
                            ),
                          ),
                          for (final id in studentIds.where(
                            (id) =>
                                !widget.options.students.any((s) => s.id == id),
                          ))
                            NalaraDropdownOption(
                              value: id,
                              label: 'Siswa tidak lagi aktif — hapus pilihan',
                            ),
                        ],
                        onChanged: (values) => setState(() {
                          studentIds = Set.of(values);
                          _selectedGroupId = null;
                          _groupNotice = null;
                        }),
                      ),
                    ),
                  ),
                  ScheduleFormSection(
                    label: 'Bidang belajar',
                    child: NalaraDropdown<String>(
                      key: const ValueKey('schedule-subject'),
                      value: subjectId,
                      validator: (id) =>
                          widget.options.subjects.any((s) => s.id == id)
                          ? null
                          : 'Pilih bidang belajar yang tersedia',
                      enabled: !state.busy,
                      menuTitle: 'Pilih bidang belajar',
                      searchHint: 'Cari bidang belajar...',
                      options: widget.options.subjects
                          .map(
                            (s) => NalaraDropdownOption(
                              value: s.id,
                              label: s.name,
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => subjectId = value!),
                    ),
                  ),
                  ScheduleTimezoneInfo(
                    timezone: timezone,
                    onOpenSettings: state.busy
                        ? null
                        : widget.onTimezoneSettings,
                  ),
                  _dateFields(state.busy),
                  ScheduleRepeatFields(
                    cubit: repeat,
                    start: start,
                    end: end,
                    timezone: timezone,
                    enabled: !state.busy,
                    studentsLabel:
                        '${studentIds.length} siswa · siswa dan bidang belajar tetap sama',
                  ),
                  const SizedBox(height: 2),
                  TutorialTarget(
                    id: 'save-schedule',
                    child: SubmitButton(
                      key: const ValueKey('schedule-save'),
                      cubit: submit,
                      label: 'Buat jadwal',
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _dateFields(bool busy) => LayoutBuilder(
    builder: (context, constraints) {
      final startField = ScheduleDateTimeCard(
        key: const ValueKey('schedule-start'),
        label: 'Mulai',
        value: start,
        timezone: timezone,
        enabled: !busy,
        onChanged: (value) => setState(() {
          final duration = end.difference(start);
          start = value;
          end = start.add(
            duration.isNegative ? const Duration(hours: 1) : duration,
          );
          repeat.anchorChanged(DateTimeUtils.local(start, timezone).weekday);
        }),
      );
      final endField = ScheduleDateTimeCard(
        key: const ValueKey('schedule-end'),
        label: 'Selesai',
        value: end,
        timezone: timezone,
        enabled: !busy,
        onChanged: (value) => setState(() => end = value),
      );
      if (constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(13) > 16) {
        return Column(children: [startField, endField]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: startField),
          const SizedBox(width: 12),
          Expanded(child: endField),
        ],
      );
    },
  );

  Future<void> _save() async {
    if (submit.state.busy || !form.currentState!.validate()) return;
    if (!end.isAfter(start)) {
      errorMessage(context, 'Waktu selesai harus setelah mulai');
      return;
    }
    final local = DateTimeUtils.local(start, timezone);
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final repeatError = repeat.validate(date);
    if (repeatError != null) {
      errorMessage(context, repeatError);
      return;
    }
    FocusScope.of(context).unfocus();
    final ok = await submit.run(() async {
      await getIt<SchedulesRepository>().create(
        ScheduleDraft(
          studentIds: List.unmodifiable(studentIds),
          subjectId: subjectId,
          startAt: start,
          endAt: end,
          timezone: timezone,
          repeat: repeat.state.enabled ? repeat.state.value : null,
        ),
      );
    });
    if (ok && mounted) {
      TeachingTutorialScope.maybeOf(context)?.guide.load();
      successMessage(context, 'Jadwal dibuat');
      finishForm(context, '/teacher/schedule');
    }
  }
}

class ReschedulePage extends StatelessWidget {
  final String id;
  const ReschedulePage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => AsyncPage<RescheduleData>(
    title: 'Ubah pertemuan',
    load: () => LoadReschedule(getIt<SchedulesRepository>())(id),
    builder: (context, data, _) =>
        _RescheduleEditor(lesson: data.lesson, schedule: data.schedule),
  );
}

class _RescheduleEditor extends StatefulWidget {
  final Lesson lesson;
  final Schedule schedule;
  const _RescheduleEditor({required this.lesson, required this.schedule});
  @override
  State<_RescheduleEditor> createState() => _RescheduleEditorState();
}

class _RescheduleEditorState extends State<_RescheduleEditor> {
  late DateTime start = widget.lesson.startAt, end = widget.lesson.endAt;
  final submit = SubmitCubit();
  String scope = 'one';
  @override
  void dispose() {
    submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: submit,
    builder: (context, state) => PageBody(
      children: [
        if (widget.schedule.recurrence == 'weekly' &&
            widget.lesson.startAt.isAfter(DateTime.now())) ...[
          ScheduleFormSection(
            label: 'Terapkan perubahan',
            child: NalaraDropdown<String>(
              value: scope,
              enabled: !state.busy,
              menuTitle: 'Ubah pertemuan mana?',
              options: const [
                NalaraDropdownOption(value: 'one', label: 'Pertemuan ini saja'),
                NalaraDropdownOption(
                  value: 'following',
                  label: 'Pertemuan ini dan berikutnya',
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => scope = value);
              },
            ),
          ),
        ],
        Text(
          scope == 'following'
              ? 'Hari dan jam baru dipakai untuk pertemuan ini dan berikutnya. Siswa tetap sama; riwayat selesai tidak diubah.'
              : widget.lesson.isGroup
              ? 'Perubahan ini berlaku untuk seluruh ${widget.lesson.participants.length} siswa pada pertemuan ini saja, bukan seluruh seri.'
              : 'Perubahan ini hanya berlaku untuk satu pertemuan.',
        ),
        const SizedBox(height: 20),
        ScheduleDateTimeCard(
          label: 'Mulai',
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
        SubmitButton(
          cubit: submit,
          onPressed: () async {
            if (!end.isAfter(start)) {
              errorMessage(context, 'Waktu selesai harus setelah mulai');
              return;
            }
            String? continuation;
            final ok = await submit.run(() async {
              if (scope == 'following') {
                continuation = await getIt<ScheduleRepeatRepository>()
                    .rescheduleFollowing(widget.lesson.id, start, end);
              } else {
                await getIt<SchedulesRepository>().reschedule(
                  widget.lesson.id,
                  start,
                  end,
                );
              }
            });
            if (ok && context.mounted) {
              successMessage(context, 'Pertemuan diperbarui');
              if (continuation != null) {
                context.go('/teacher/schedule/$continuation');
              } else {
                finishForm(context, '/teacher/sessions/${widget.lesson.id}');
              }
            }
          },
        ),
      ],
    ),
  );
}

class SeriesSessionsPage extends StatelessWidget {
  final String id;
  const SeriesSessionsPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => PagedListPage<Lesson>(
    title: 'Pertemuan dalam seri',
    empty: 'Tidak ada sesi.',
    emptyArtwork: 'assets/Empty/Jadwal kosong.png',
    load: (page) =>
        getIt<SchedulesRepository>().sessions(page: page, scheduleId: id),
    itemBuilder: (context, lesson, reload) => LessonCard(
      lesson: lesson,
      onTap: () async {
        await context.push('/teacher/sessions/${lesson.id}');
        reload();
      },
    ),
  );
}
