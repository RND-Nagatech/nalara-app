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
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/schedules_repository.dart';
import '../../domain/usecases/load_teaching_options.dart';
import '../widgets/schedule_form_fields.dart';
import '../widgets/schedule_form_header.dart';
import '../widgets/schedule_form_style.dart';
import '../widgets/schedule_prerequisites.dart';
import 'schedule_agenda_page.dart';

export 'session_detail_page.dart';
export 'schedule_detail_page.dart';

class SchedulesPage extends StatelessWidget {
  final bool attendance;
  final DateTime? initialDate;
  final String? initialPeriod;
  final String timezone;
  const SchedulesPage({
    super.key,
    this.attendance = false,
    this.initialDate,
    this.initialPeriod,
    this.timezone = 'Asia/Jakarta',
  });
  @override
  Widget build(BuildContext context) => ScheduleAgendaPage(
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
  final String? studentId;
  const ScheduleFormPage({super.key, this.studentId});

  @override
  State<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends State<ScheduleFormPage>
    with TeachingCatalogRefresh<ScheduleFormPage> {
  late final _loader = LoadCubit<TeachingOptions>(
    getIt<LoadTeachingOptions>().call,
  )..load();

  @override
  void onTeachingCatalogChanged() => _loader.load();

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) await _loader.load();
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
                      if (state.status == LoadStatus.error) {
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
                        child: _ScheduleEditor(
                          options: options,
                          studentId: widget.studentId,
                        ),
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
  final String? studentId;
  const _ScheduleEditor({required this.options, this.studentId});
  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  final form = GlobalKey<FormState>(), submit = SubmitCubit();
  late String studentId =
      widget.options.students.any((s) => s.id == widget.studentId)
      ? widget.studentId!
      : widget.options.students.first.id;
  late String subjectId = widget.options.subjects.first.id;
  String timezone = 'Asia/Jakarta';
  DateTime start = DateTime.now().toUtc().add(const Duration(hours: 1)),
      end = DateTime.now().toUtc().add(const Duration(hours: 2));
  final repeat = TextEditingController(text: '1');
  @override
  void dispose() {
    repeat.dispose();
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
                  ScheduleFormSection(
                    label: 'Siswa',
                    child: NalaraDropdown<String>(
                      key: const ValueKey('schedule-student'),
                      value: studentId,
                      enabled: !state.busy,
                      menuTitle: 'Pilih siswa',
                      searchHint: 'Cari siswa...',
                      options: widget.options.students
                          .map(
                            (s) => NalaraDropdownOption(
                              value: s.id,
                              label: s.name,
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => studentId = value!),
                    ),
                  ),
                  ScheduleFormSection(
                    label: 'Bidang belajar',
                    child: NalaraDropdown<String>(
                      key: const ValueKey('schedule-subject'),
                      value: subjectId,
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
                  ScheduleFormSection(
                    label: 'Zona waktu',
                    child: NalaraDropdown<String>(
                      key: const ValueKey('schedule-timezone'),
                      value: timezone,
                      enabled: !state.busy,
                      menuTitle: 'Pilih zona waktu',
                      options:
                          const [
                                'Asia/Jakarta',
                                'Asia/Makassar',
                                'Asia/Jayapura',
                              ]
                              .map(
                                (zone) => NalaraDropdownOption(
                                  value: zone,
                                  label: zone,
                                ),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => timezone = value!),
                    ),
                  ),
                  _dateFields(state.busy),
                  ScheduleFormSection(
                    label: 'Jumlah pertemuan mingguan',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const ValueKey('schedule-repeat'),
                          controller: repeat,
                          enabled: !state.busy,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          validator: (value) {
                            final count = int.tryParse(value ?? '');
                            return count == null || count < 1 || count > 52
                                ? 'Masukkan 1–52 pertemuan'
                                : null;
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1 = satu pertemuan; 2–52 = seri berulang',
                          style: ScheduleFormStyle.supporting,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  SubmitButton(
                    key: const ValueKey('schedule-save'),
                    cubit: submit,
                    label: 'Buat jadwal',
                    onPressed: _save,
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
          start = value;
          if (!end.isAfter(start)) end = start.add(const Duration(hours: 1));
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
    FocusScope.of(context).unfocus();
    final ok = await submit.run(() async {
      await getIt<SchedulesRepository>().create(
        ScheduleDraft(
          studentId: studentId,
          subjectId: subjectId,
          startAt: start,
          endAt: end,
          timezone: timezone,
          repeatCount: int.parse(repeat.text),
        ),
      );
    });
    if (ok && mounted) {
      successMessage(context, 'Jadwal dibuat');
      finishForm(context, '/teacher/schedule');
    }
  }
}

class ReschedulePage extends StatelessWidget {
  final String id;
  const ReschedulePage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => AsyncPage<Lesson>(
    title: 'Ubah pertemuan',
    load: () => getIt<SchedulesRepository>().session(id),
    builder: (context, lesson, _) => _RescheduleEditor(lesson: lesson),
  );
}

class _RescheduleEditor extends StatefulWidget {
  final Lesson lesson;
  const _RescheduleEditor({required this.lesson});
  @override
  State<_RescheduleEditor> createState() => _RescheduleEditorState();
}

class _RescheduleEditorState extends State<_RescheduleEditor> {
  late DateTime start = widget.lesson.startAt, end = widget.lesson.endAt;
  final submit = SubmitCubit();
  @override
  void dispose() {
    submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const Text('Perubahan ini hanya berlaku untuk satu pertemuan.'),
      const SizedBox(height: 20),
      DateTimeField(
        label: 'Mulai',
        value: start,
        onChanged: (value) => setState(() => start = value),
      ),
      DateTimeField(
        label: 'Selesai',
        value: end,
        onChanged: (value) => setState(() => end = value),
      ),
      SubmitButton(
        cubit: submit,
        onPressed: () async {
          if (!end.isAfter(start)) {
            errorMessage(context, 'Waktu selesai harus setelah mulai');
            return;
          }
          final ok = await submit.run(
            () => getIt<SchedulesRepository>().reschedule(
              widget.lesson.id,
              start,
              end,
            ),
          );
          if (ok && context.mounted) {
            successMessage(context, 'Pertemuan diperbarui');
            finishForm(context, '/teacher/sessions/${widget.lesson.id}');
          }
        },
      ),
    ],
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
