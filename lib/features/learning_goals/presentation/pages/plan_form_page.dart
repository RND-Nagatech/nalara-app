import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../teaching_guide/presentation/teaching_tutorial_scope.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../../utils/validators.dart';
import '../../../schedules/domain/usecases/load_teaching_options.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/repositories/learning_repository.dart';
import '../bloc/plan_form_cubit.dart';
import '../widgets/plan_form_header.dart';
import '../widgets/plan_form_style.dart';
import '../widgets/plan_period_field.dart';
import '../widgets/plan_target_editor.dart';

class PlanFormPage extends StatefulWidget {
  final String? studentId, sourceTargetId;
  const PlanFormPage({super.key, this.studentId, this.sourceTargetId});
  @override
  State<PlanFormPage> createState() => _PlanFormPageState();
}

class _PlanFormPageState extends State<PlanFormPage>
    with TeachingCatalogRefresh<PlanFormPage> {
  late PlanFormCubit _loader;
  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _loader = PlanFormCubit(
      getIt<LoadTeachingOptions>(),
      getIt<LearningRepository>(),
      sourceTargetId: widget.sourceTargetId,
    )..load();
  }

  @override
  void onTeachingCatalogChanged() => _loader.load();
  @override
  void didUpdateWidget(covariant PlanFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId ||
        oldWidget.sourceTargetId != widget.sourceTargetId) {
      _loader.close();
      _bind();
    }
  }

  @override
  void dispose() {
    _loader.close();
    super.dispose();
  }

  Future<void> _open(String path) async {
    final loader = _loader;
    await context.push(path);
    if (mounted && identical(loader, _loader)) await loader.load();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: PlanFormStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: PlanFormStyle.cream,
        body: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  NalaraHeader(
                    child: PlanFormHeader(
                      title: widget.sourceTargetId == null
                          ? 'Buat rencana & target'
                          : 'Teruskan target',
                      onBack: () => finishForm(context, '/teacher/targets'),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<PlanFormCubit, PlanFormState>(
                      bloc: _loader,
                      builder: (context, state) {
                        if (state.data == null) {
                          return ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              PlanFormHero(
                                continuing: widget.sourceTargetId != null,
                              ),
                              if (state.error != null)
                                ErrorNotice(state.error!, retry: _loader.load)
                              else
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          );
                        }
                        return _PlanEditor(
                          key: ValueKey((
                            widget.studentId,
                            widget.sourceTargetId,
                          )),
                          state: state,
                          studentId: widget.studentId,
                          reload: _loader.load,
                          open: _open,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PlanEditor extends StatefulWidget {
  final PlanFormState state;
  final String? studentId;
  final Future<void> Function() reload;
  final Future<void> Function(String) open;
  const _PlanEditor({
    super.key,
    required this.state,
    required this.reload,
    required this.open,
    this.studentId,
  });
  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<_PlanEditor> {
  final _form = GlobalKey<FormState>(), _submit = SubmitCubit();
  final _scroll = ScrollController();
  final _title = TextEditingController(text: 'Rencana belajar mingguan');
  late final List<PlanTargetFields> _targets = [
    PlanTargetFields(0, widget.state.data!.source),
  ];
  int _nextTargetId = 1;
  late String? _studentId =
      widget.state.data!.source?.studentId ??
      widget.studentId ??
      _options.students.firstOrNull?.id;
  late String? _subjectId =
      widget.state.data!.source?.subjectId ?? _options.subjects.firstOrNull?.id;
  DateTime _start = DateTime.now().toUtc(),
      _end = DateTime.now().toUtc().add(const Duration(days: 6));
  TeachingOptions get _options => widget.state.data!.options;

  @override
  void initState() {
    super.initState();
    final sourcePlan = widget.state.data!.sourcePlan;
    if (sourcePlan != null) {
      final previousEnd = DateTimeUtils.local(sourcePlan.endAt);
      _start = DateTimeUtils.fromWallTime(
        DateTime(previousEnd.year, previousEnd.month, previousEnd.day + 1),
        0,
        0,
      );
      _end = _start.add(const Duration(days: 6));
      _title.text = 'Rencana belajar lanjutan';
    }
  }

  @override
  void didUpdateWidget(covariant _PlanEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Initialize newly available choices, but never replace an existing ID/draft.
    _studentId ??= _options.students.firstOrNull?.id;
    _subjectId ??= _options.subjects.firstOrNull?.id;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _title.dispose();
    for (final target in _targets) {
      target.dispose();
    }
    _submit.close();
    super.dispose();
  }

  void _remove(PlanTargetFields target) {
    if (_targets.length == 1 || _submit.state.busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _targets.remove(target));
    // Let TextFormField detach its listeners before releasing its controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) => target.dispose());
  }

  void _add() {
    if (_submit.state.busy) return;
    final target = PlanTargetFields(_nextTargetId++);
    setState(() => _targets.add(target));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchor = target.anchor.currentContext;
      if (mounted && anchor != null) {
        Scrollable.ensureVisible(
          anchor,
          alignment: .05,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _save() async {
    if (_submit.state.busy ||
        widget.state.loading ||
        widget.state.error != null) {
      return;
    }
    FocusScope.of(context).unfocus();
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      final first = invalid.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && first.mounted) {
          Scrollable.ensureVisible(
            first.context,
            alignment: .12,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
      return;
    }
    final localStart = DateTimeUtils.local(_start),
        localEnd = DateTimeUtils.local(_end);
    final startAt = DateTimeUtils.fromWallTime(localStart, 0, 0),
        endAt = DateTimeUtils.fromWallTime(
          DateTime(localEnd.year, localEnd.month, localEnd.day + 1),
          0,
          0,
        ).subtract(const Duration(microseconds: 1));
    if (endAt.isBefore(startAt)) {
      errorMessage(context, 'Akhir periode harus setelah awal');
      return;
    }
    final draft = PlanDraft(
      studentId: _studentId!,
      subjectId: _subjectId!,
      title: _title.text,
      startAt: startAt,
      endAt: endAt,
      targets: _targets.map((target) => target.draft).toList(),
    );
    final router = GoRouter.maybeOf(context);
    final location = router?.state.uri;
    LearningPlan? plan;
    final ok = await _submit.run(() async {
      plan = await getIt<LearningRepository>().createPlan(draft);
    });
    if (!mounted) return;
    final visible =
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        (router == null || router.state.uri == location);
    if (!visible) return;
    if (ok) {
      TeachingTutorialScope.maybeOf(context)?.guide.load();
      successMessage(context, 'Rencana dan target disimpan');
      finishForm(context, '/teacher/plans/${plan!.id}');
    } else if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: _submit,
    builder: (context, submit) => LayoutBuilder(
      builder: (context, constraints) {
        final inlineActions =
            constraints.maxHeight < 420 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        final enabled =
            !submit.busy && !widget.state.loading && widget.state.error == null;
        final actions = _actions(submit, enabled);
        return Form(
          key: _form,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.reload,
                  child: ListView(
                    key: const ValueKey('plan-form-scroll'),
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    children: [
                      PlanFormHero(
                        continuing: widget.state.data!.source != null,
                      ),
                      if (widget.state.loading) const LinearProgressIndicator(),
                      if (widget.state.error != null)
                        ErrorNotice(widget.state.error!, retry: widget.reload),
                      if (submit.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              submit.error!,
                              key: const ValueKey('plan-submit-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      if (_options.students.isEmpty ||
                          _options.subjects.isEmpty)
                        _prerequisites(),
                      if (widget.state.data!.source != null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Buat target lanjutan pada periode baru. Target baru dimulai dari 0%; target dan riwayat asal tetap tersedia.',
                            style: PlanFormStyle.supporting,
                          ),
                        ),
                      AbsorbPointer(
                        key: const ValueKey('plan-fields'),
                        absorbing: !enabled,
                        child: Column(
                          children: [
                            _planCard(enabled),
                            PlanFormCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Target dalam periode ini',
                                    style: PlanFormStyle.label.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'Tambahkan beberapa target untuk rencana belajar ini.',
                                    style: PlanFormStyle.supporting,
                                  ),
                                  for (
                                    var index = 0;
                                    index < _targets.length;
                                    index++
                                  )
                                    PlanTargetEditor(
                                      key: ObjectKey(_targets[index]),
                                      fields: _targets[index],
                                      number: index + 1,
                                      enabled: enabled,
                                      onRemove: enabled && _targets.length > 1
                                          ? () => _remove(_targets[index])
                                          : null,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (inlineActions) actions,
                    ],
                  ),
                ),
              ),
              if (!inlineActions) actions,
            ],
          ),
        );
      },
    ),
  );

  Widget _planCard(bool enabled) => PlanFormCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlanFormLabel('Nama rencana belajar', requiredField: true),
        TutorialTarget(
          id: 'form-target',
          child: TextFormField(
            key: const ValueKey('plan-name'),
            controller: _title,
            enabled: enabled,
            validator: Validators.name,
            maxLength: 200,
            style: PlanFormStyle.supporting.copyWith(color: PlanFormStyle.ink),
            decoration: const InputDecoration(
              hintText: 'Masukkan nama rencana belajar',
            ),
          ),
        ),
        const SizedBox(height: 10),
        const PlanFormLabel('Siswa', requiredField: true),
        NalaraDropdown<String>(
          key: const ValueKey('plan-student'),
          value: _studentId,
          enabled: enabled && _options.students.isNotEmpty,
          hint: 'Pilih siswa',
          menuTitle: 'Pilih siswa',
          searchHint: 'Cari siswa...',
          options: _options.students
              .map(
                (student) => NalaraDropdownOption(
                  value: student.id,
                  label: student.name,
                ),
              )
              .toList(),
          validator: (value) =>
              _options.students.any((student) => student.id == value)
              ? null
              : 'Pilih siswa aktif yang tersedia.',
          onChanged: (value) => setState(() => _studentId = value),
        ),
        const SizedBox(height: 16),
        const PlanFormLabel('Bidang belajar', requiredField: true),
        NalaraDropdown<String>(
          key: const ValueKey('plan-subject'),
          value: _subjectId,
          enabled: enabled && _options.subjects.isNotEmpty,
          hint: 'Pilih bidang belajar',
          menuTitle: 'Pilih bidang belajar',
          searchHint: 'Cari bidang belajar...',
          options: _options.subjects
              .map(
                (subject) => NalaraDropdownOption(
                  value: subject.id,
                  label: subject.name,
                ),
              )
              .toList(),
          validator: (value) =>
              _options.subjects.any((subject) => subject.id == value)
              ? null
              : 'Pilih bidang belajar yang tersedia.',
          onChanged: (value) => setState(() => _subjectId = value),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              PlanPeriodField(
                key: const ValueKey('plan-start'),
                label: 'Awal periode',
                value: _start,
                enabled: enabled,
                onChanged: (value) {
                  if (mounted && !_submit.state.busy) {
                    setState(() => _start = value);
                  }
                },
              ),
              PlanPeriodField(
                key: const ValueKey('plan-end'),
                label: 'Akhir periode',
                value: _end,
                enabled: enabled,
                onChanged: (value) {
                  if (mounted && !_submit.state.busy) {
                    setState(() => _end = value);
                  }
                },
              ),
            ];
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 18) {
              return Column(
                children: [fields[0], const SizedBox(height: 14), fields[1]],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: 16),
                Expanded(child: fields[1]),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _actions(SubmitState state, bool enabled) => ColoredBox(
    color: PlanFormStyle.cream,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('plan-add-target'),
              onPressed: enabled ? _add : null,
              icon: const Icon(Icons.add, size: 23),
              label: const Text('Tambah target lagi'),
            ),
            const SizedBox(height: 9),
            TutorialTarget(
              id: 'save-target',
              child: FilledButton(
                key: const ValueKey('plan-save'),
                onPressed:
                    enabled &&
                        _options.students.isNotEmpty &&
                        _options.subjects.isNotEmpty
                    ? _save
                    : null,
                child: state.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Simpan rencana & target',
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _prerequisites() => PlanFormCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Rencana belajar membutuhkan siswa aktif dan bidang belajar.',
          style: PlanFormStyle.supporting,
        ),
        if (_options.students.isEmpty)
          TextButton(
            onPressed: () => widget.open('/teacher/students/new'),
            child: const Text('Tambah siswa'),
          ),
        if (_options.subjects.isEmpty)
          TextButton(
            onPressed: () => widget.open('/teacher/subjects/new'),
            child: const Text('Tambah bidang belajar'),
          ),
      ],
    ),
  );
}
