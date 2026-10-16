import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_page_header.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../utils/injector.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/validators.dart';
import '../../../progress_history/domain/entities/progress_record.dart';
import '../../../progress_history/presentation/pages/history_page.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/repositories/learning_repository.dart';
import '../widgets/plan_detail_style.dart';

export 'learning_plans_page.dart';
export 'plan_form_page.dart';
export 'plan_detail_page.dart';
export 'update_progress_page.dart';

class _TargetFields {
  final title = TextEditingController(),
      description = TextEditingController(),
      criteria = TextEditingController();
  String priority = 'normal';
  _TargetFields([LearningTarget? source]) {
    if (source != null) {
      title.text = source.title;
      description.text = source.description;
      criteria.text = source.successCriteria;
      priority = source.priority;
    }
  }
  TargetDraft get draft => TargetDraft(
    title: title.text,
    description: description.text,
    successCriteria: criteria.text,
    priority: priority,
  );
  void dispose() {
    title.dispose();
    description.dispose();
    criteria.dispose();
  }
}

class _TargetInputs extends StatelessWidget {
  final _TargetFields fields;
  const _TargetInputs(this.fields);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      FormFieldSpace(
        child: TextFormField(
          controller: fields.title,
          validator: Validators.name,
          maxLength: 200,
          decoration: const InputDecoration(labelText: 'Judul target'),
        ),
      ),
      FormFieldSpace(
        child: TextFormField(
          controller: fields.description,
          maxLength: 3000,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
        ),
      ),
      FormFieldSpace(
        child: TextFormField(
          controller: fields.criteria,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Indikator keberhasilan (opsional)',
          ),
        ),
      ),
      FormFieldSpace(
        child: NalaraDropdown<String>(
          value: fields.priority,
          decoration: const InputDecoration(labelText: 'Prioritas'),
          options: ['low', 'normal', 'high']
              .map(
                (value) => NalaraDropdownOption(
                  value: value,
                  label: statusLabel(value),
                ),
              )
              .toList(),
          onChanged: (value) => fields.priority = value!,
        ),
      ),
    ],
  );
}

/// Presentation data shared by teacher and scoped, read-only portal loaders.
class TargetDetailData {
  final LearningTarget target;
  final String planTitle, studentName, subjectName;
  final DateTime? startAt, endAt;
  final List<ProgressRecord>? history;

  const TargetDetailData({
    required this.target,
    this.planTitle = '',
    this.studentName = '',
    this.subjectName = '',
    this.startAt,
    this.endAt,
    this.history,
  });
}

class TargetDetailPage extends StatefulWidget {
  final String id;
  final Future<TargetDetailData> Function(String id)? loadTarget;
  final bool readOnly;
  final String routePrefix;
  const TargetDetailPage({
    super.key,
    required this.id,
    this.loadTarget,
    this.readOnly = false,
    this.routePrefix = '/teacher',
  }) : assert(!readOnly || loadTarget != null);
  @override
  State<TargetDetailPage> createState() => _TargetDetailPageState();
}

class _TargetDetailPageState extends State<TargetDetailPage>
    with TeachingCatalogRefresh<TargetDetailPage> {
  late LoadCubit<TargetDetailData> _loader;
  final submit = SubmitCubit();

  @override
  void onTeachingCatalogChanged() => _loader.load();

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    final id = widget.id;
    final loadTarget = widget.loadTarget;
    _loader = LoadCubit(
      () async => loadTarget != null
          ? await loadTarget(id)
          : TargetDetailData(
              target: await getIt<LearningRepository>().target(id),
            ),
    )..load();
  }

  @override
  void didUpdateWidget(covariant TargetDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.loadTarget != widget.loadTarget) {
      _loader.close();
      _bind();
    }
  }

  @override
  void dispose() {
    _loader.close();
    submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: PlanDetailStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: PlanDetailStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  NalaraHeader(child: _header()),
                  Expanded(
                    child:
                        BlocBuilder<
                          LoadCubit<TargetDetailData>,
                          LoadState<TargetDetailData>
                        >(
                          bloc: _loader,
                          builder: (context, state) => RefreshIndicator(
                            color: PlanDetailStyle.green,
                            onRefresh: _loader.load,
                            child: state.value == null
                                ? ListView(
                                    key: ValueKey(
                                      'target-detail-scroll-${widget.id}',
                                    ),
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(20),
                                    children: [
                                      if (state.status == LoadStatus.error)
                                        ErrorNotice(
                                          state.error!,
                                          retry: _loader.load,
                                        )
                                      else
                                        const Padding(
                                          padding: EdgeInsets.all(60),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                    ],
                                  )
                                : _body(
                                    state.value!,
                                    state.status == LoadStatus.loading,
                                    state.error,
                                  ),
                          ),
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

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('target-detail-back'),
          tooltip: 'Kembali',
          onPressed: () => finishForm(context, '${widget.routePrefix}/targets'),
          style: IconButton.styleFrom(
            foregroundColor: PlanDetailStyle.green,
            minimumSize: const Size(44, 44),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 25),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Detail target',
            style: TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: PlanDetailStyle.ink,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _body(TargetDetailData data, bool loading, String? error) {
    final target = data.target;
    return ListView(
      key: ValueKey('target-detail-scroll-${widget.id}'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (error != null) ErrorNotice(error, retry: _loader.load),
        _hero(target),
        const SizedBox(height: 14),
        if (data.studentName.isNotEmpty || data.planTitle.isNotEmpty) ...[
          _context(data),
          const SizedBox(height: 14),
        ],
        _progress(target),
        const SizedBox(height: 14),
        _summary(target),
        const SizedBox(height: 14),
        if (!widget.readOnly &&
            !['archived', 'cancelled'].contains(target.status)) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('target-update-progress'),
              onPressed: () => _open(
                '/teacher/targets/${Uri.encodeComponent(widget.id)}/update-progress',
              ),
              child: const Text('Update progress'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (!widget.readOnly)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const ValueKey('target-history'),
              onPressed: () => _open(
                '/teacher/targets/${Uri.encodeComponent(widget.id)}/history',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: PlanDetailStyle.ink,
                side: const BorderSide(
                  color: PlanDetailStyle.muted,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: const Text('Riwayat perkembangan'),
            ),
          ),
        if (data.history != null) ...[
          const Text('Riwayat perkembangan', style: PlanDetailStyle.title),
          const SizedBox(height: 14),
          if (data.history!.isEmpty)
            const PlanDetailCard(
              child: Text(
                'Belum ada perubahan progress yang dibagikan pada target ini.',
                style: PlanDetailStyle.body,
              ),
            )
          else
            for (final record in data.history!)
              HistoryRecordCard(key: ValueKey(record.id), record: record),
        ],
        const SizedBox(height: 14),
        _actions(target),
        if (!widget.readOnly && target.status != 'archived') ...[
          const SizedBox(height: 18),
          SubmitButton(
            key: const ValueKey('target-archive'),
            cubit: submit,
            label: 'Arsipkan target',
            onPressed: () => _archive(target),
          ),
        ],
      ],
    );
  }

  Widget _context(TargetDetailData data) => PlanDetailCard(
    key: const ValueKey('target-context-card'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heroField('Siswa', data.studentName),
        const SizedBox(height: 14),
        _heroField('Bidang belajar', data.subjectName),
        const SizedBox(height: 14),
        _heroField('Rencana belajar', data.planTitle),
        if (data.startAt != null && data.endAt != null) ...[
          const SizedBox(height: 14),
          _heroField(
            'Periode',
            '${DateTimeUtils.date(data.startAt!)} – ${DateTimeUtils.date(data.endAt!)}',
          ),
        ],
      ],
    ),
  );

  Widget _hero(LearningTarget target) => PlanDetailCard(
    key: const ValueKey('target-hero-card'),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth < 390 ? 122.0 : 158.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [_statusPill(target), _priorityPill(target)],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.title,
                        style: PlanDetailStyle.title.copyWith(
                          fontSize: 25,
                          height: 1.18,
                          color: PlanDetailStyle.ink,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _heroField('Deskripsi', target.description),
                      const SizedBox(height: 14),
                      _heroField(
                        'Indikator keberhasilan',
                        target.successCriteria,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IgnorePointer(
                  child: Image.asset(
                    'assets/Icon/Icon detail target.png',
                    width: imageWidth,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  Widget _progress(LearningTarget target) => PlanDetailCard(
    key: const ValueKey('target-progress-card'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text('Progress target', style: PlanDetailStyle.title),
            ),
            const SizedBox(width: 12),
            _aggregate(target),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${target.progress}%',
          style: PlanDetailStyle.title.copyWith(
            fontSize: 32,
            height: 1.1,
            color: PlanDetailStyle.ink,
          ),
        ),
        const SizedBox(height: 14),
        PlanProgressTrack(progress: target.progress),
        const SizedBox(height: 12),
        const Text(
          'Progress dihitung dari pencapaian tiap indikator sesuai rencana.',
          style: PlanDetailStyle.body,
        ),
      ],
    ),
  );

  Widget _aggregate(LearningTarget target) => Container(
    padding: const EdgeInsets.fromLTRB(13, 10, 13, 9),
    decoration: BoxDecoration(
      color: PlanDetailStyle.paleGreen,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Agregat rencana', style: PlanDetailStyle.body),
        const SizedBox(height: 2),
        Text(
          target.planProgress == null ? '—' : '${target.planProgress}%',
          style: PlanDetailStyle.title.copyWith(
            fontSize: 19,
            color: PlanDetailStyle.green,
          ),
        ),
      ],
    ),
  );

  Widget _summary(LearningTarget target) => PlanDetailCard(
    key: const ValueKey('target-summary-card'),
    child: Row(
      children: [
        Expanded(
          child: _summaryItem(
            Icons.calendar_today_rounded,
            'Status',
            statusLabel(target.status),
          ),
        ),
        Container(width: 1, height: 46, color: const Color(0xFFE2E5E1)),
        Expanded(
          child: _summaryItem(
            Icons.format_list_bulleted_rounded,
            'Prioritas',
            statusLabel(target.priority),
          ),
        ),
      ],
    ),
  );

  Widget _summaryItem(IconData icon, String label, String value) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: PlanDetailStyle.paleGreen,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 21, color: PlanDetailStyle.green),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: PlanDetailStyle.body),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PlanDetailStyle.title.copyWith(
                fontSize: 15,
                color: PlanDetailStyle.ink,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _actions(LearningTarget target) => PlanDetailCard(
    key: const ValueKey('target-actions-card'),
    child: Column(
      children: [
        if (!widget.readOnly) ...[
          _action(
            key: const ValueKey('target-edit'),
            title: 'Edit target',
            description:
                'Ubah detail target, deskripsi, indikator, atau prioritas',
            onTap: () => _open(
              '/teacher/targets/${Uri.encodeComponent(widget.id)}/edit',
            ),
          ),
          _actionDivider,
          _action(
            key: const ValueKey('target-continue'),
            title: 'Teruskan ke periode baru',
            description: 'Gunakan target ini untuk periode selanjutnya',
            onTap: () => _open(
              '/teacher/targets/new?sourceTargetId=${Uri.encodeComponent(widget.id)}',
            ),
          ),
          _actionDivider,
        ],
        _action(
          key: const ValueKey('target-plan'),
          title: 'Lihat rencana belajar',
          description: 'Lihat detail rencana dan target lainnya',
          onTap: () => _open(
            '${widget.routePrefix}/plans/${Uri.encodeComponent(target.planId)}',
          ),
        ),
      ],
    ),
  );

  static const _actionDivider = Divider(
    height: 1,
    thickness: .7,
    color: Color(0xFFE7E9EB),
  );

  Widget _action({
    required Key key,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    child: InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PlanDetailStyle.title.copyWith(
                      fontSize: 15,
                      color: PlanDetailStyle.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(description, style: PlanDetailStyle.body),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: PlanDetailStyle.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _statusPill(LearningTarget target) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: target.status == 'active'
          ? PlanDetailStyle.paleGreen
          : const Color(0xFFF0EEE8),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          size: 11,
          color: target.status == 'active'
              ? const Color(0xFF23934A)
              : PlanDetailStyle.muted,
        ),
        const SizedBox(width: 8),
        Text(
          statusLabel(target.status),
          style: PlanDetailStyle.body.copyWith(
            color: target.status == 'active'
                ? const Color(0xFF166534)
                : PlanDetailStyle.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _priorityPill(LearningTarget target) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2F0),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      'Prioritas ${statusLabel(target.priority)}',
      style: PlanDetailStyle.body.copyWith(
        color: PlanDetailStyle.ink,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _heroField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: PlanDetailStyle.body.copyWith(fontSize: 13.5)),
      const SizedBox(height: 4),
      Text(
        value.isEmpty ? 'Belum diisi' : value,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: PlanDetailStyle.body.copyWith(
          color: PlanDetailStyle.ink,
          fontSize: 14.5,
          height: 1.4,
        ),
      ),
    ],
  );

  Future<void> _open(String route) async {
    final loader = _loader;
    await context.push(route);
    if (mounted && identical(loader, _loader)) await loader.load();
  }

  Future<void> _archive(LearningTarget target) async {
    if (widget.readOnly) return;
    if (!await confirmAction(
      context,
      'Arsipkan target? Target ini tidak akan dihitung dalam agregat, tetapi riwayat tetap tersimpan.',
    )) {
      return;
    }
    final ok = await submit.run(
      () => getIt<LearningRepository>().archiveTarget(target.id),
    );
    if (ok && mounted) {
      successMessage(context, 'Target diarsipkan');
      await _loader.load();
    }
  }
}

class TargetFormPage extends StatelessWidget {
  final String? planId, targetId;
  const TargetFormPage({super.key, this.planId, this.targetId});
  @override
  Widget build(BuildContext context) => targetId == null
      ? NalaraPageScaffold(
          title: 'Tambah target',
          body: _TargetEditor(planId: planId!),
        )
      : AsyncPage<LearningTarget>(
          title: 'Edit target',
          load: () => getIt<LearningRepository>().target(targetId!),
          builder: (context, target, _) => _TargetEditor(target: target),
        );
}

class _TargetEditor extends StatefulWidget {
  final String? planId;
  final LearningTarget? target;
  const _TargetEditor({this.planId, this.target});
  @override
  State<_TargetEditor> createState() => _TargetEditorState();
}

class _TargetEditorState extends State<_TargetEditor> {
  final form = GlobalKey<FormState>(), submit = SubmitCubit();
  late final fields = _TargetFields(widget.target);
  @override
  void dispose() {
    fields.dispose();
    submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: PageBody(
      children: [
        _TargetInputs(fields),
        SubmitButton(
          cubit: submit,
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            final ok = await submit.run(() async {
              if (widget.target == null) {
                await getIt<LearningRepository>().addTarget(
                  widget.planId!,
                  fields.draft,
                );
              } else {
                await getIt<LearningRepository>().editTarget(
                  widget.target!.id,
                  fields.draft,
                );
              }
            });
            if (ok && context.mounted) {
              successMessage(context, 'Target disimpan');
              finishForm(
                context,
                widget.target == null
                    ? '/teacher/plans/${widget.planId}'
                    : '/teacher/targets/${widget.target!.id}',
              );
            }
          },
        ),
      ],
    ),
  );
}
