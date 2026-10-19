import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../utils/color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/domain/page.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../../utils/validators.dart';
import '../../domain/entities/lesson_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../schedules/domain/repositories/schedules_repository.dart';
import '../../../schedules/presentation/pages/schedules_pages.dart';
import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../learning_goals/domain/repositories/learning_repository.dart';
import '../../../students/domain/repositories/students_repository.dart';
import '../widgets/report_detail_content.dart';
import '../widgets/report_detail_style.dart';
import '../widgets/reports_header.dart';
import '../widgets/reports_style.dart';
import '../widgets/reports_tab_body.dart';
import '../../../tutor_tools/domain/tutor_tools.dart';

const _reportStatuses = <String?>[null, 'draft', 'published'];
const _reportStatusLabels = ['Semua', 'Draft', 'Terbit'];

class ReportsPage extends StatefulWidget {
  final String? subtitle;
  final String? studentId;
  final Future<PageResult<LessonReport>> Function(int page, String? studentId)?
  loadReports;
  final bool readOnly;
  final String routePrefix;
  const ReportsPage({
    super.key,
    this.studentId,
    this.loadReports,
    this.readOnly = false,
    this.routePrefix = '/teacher',
    this.subtitle,
  }) : assert(!readOnly || loadReports != null);
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with TickerProviderStateMixin, TeachingCatalogRefresh<ReportsPage> {
  late TabController _tabs;
  final _pages = <String?, int>{};
  final _loaders = <String?, LoadCubit<PageResult<LessonReport>>>{};
  var _activeIndex = 0;

  List<String?> get _statuses =>
      widget.readOnly ? const ['published'] : _reportStatuses;
  List<String> get _statusLabels =>
      widget.readOnly ? const ['Terbit'] : _reportStatusLabels;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this)
      ..addListener(_tabChanged);
    _bindLoaders();
  }

  void _bindLoaders() {
    for (final status in _statuses) {
      _pages[status] = 1;
      _loaders[status] = _newLoader(status);
    }
    _currentLoader.load();
  }

  LoadCubit<PageResult<LessonReport>> _newLoader(String? status) {
    final studentId = widget.studentId;
    final loadReports = widget.loadReports;
    return LoadCubit<PageResult<LessonReport>>(
      () => loadReports != null
          ? loadReports(_pages[status] ?? 1, studentId)
          : getIt<ReportsRepository>().list(
              page: _pages[status] ?? 1,
              status: status,
              studentId: studentId,
            ),
      isEmpty: (value) => value.items.isEmpty,
      append: appendPage,
    );
  }

  String? get _status => _statuses[_activeIndex];
  LoadCubit<PageResult<LessonReport>> get _currentLoader => _loaders[_status]!;

  @override
  void onTeachingCatalogChanged() => _reload(_status, resetPage: true);

  void _tabChanged() {
    if (!mounted) return;
    if (_activeIndex != _tabs.index) {
      setState(() => _activeIndex = _tabs.index);
    }
    if (!_tabs.indexIsChanging) {
      _reload(_statuses[_tabs.index], resetPage: true);
    }
  }

  Future<void> _reload(
    String? status, {
    bool resetPage = false,
    bool append = false,
  }) async {
    if (resetPage) _pages[status] = 1;
    final current = _loaders[status]!.state.value;
    if (!append && !resetPage && current != null) {
      append = (_pages[status] ?? 1) > current.page;
    }
    await _loaders[status]!.load(append: append);
  }

  Future<void> _open(String route) async {
    final loader = _currentLoader;
    await context.push(route);
    if (mounted && identical(loader, _currentLoader)) {
      await _reload(_status, resetPage: true);
    }
  }

  @override
  void didUpdateWidget(covariant ReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId ||
        oldWidget.loadReports != widget.loadReports ||
        oldWidget.readOnly != widget.readOnly) {
      for (final loader in _loaders.values) {
        loader.close();
      }
      _loaders.clear();
      _pages.clear();
      if (oldWidget.readOnly != widget.readOnly) {
        _tabs.removeListener(_tabChanged);
        _tabs.dispose();
        _activeIndex = 0;
        _tabs = TabController(length: _statuses.length, vsync: this)
          ..addListener(_tabChanged);
      }
      _bindLoaders();
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
    for (final loader in _loaders.values) {
      loader.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
    ),
    child: Theme(
      data: ReportsStyle.theme(Theme.of(context)),
      child:
          BlocBuilder<
            LoadCubit<PageResult<LessonReport>>,
            LoadState<PageResult<LessonReport>>
          >(
            bloc: _currentLoader,
            builder: (context, state) {
              final tabHeight = math.max(
                48.0,
                MediaQuery.textScalerOf(context).scale(13) * 1.4 + 16,
              );
              final tabs = TabBar(
                key: const ValueKey('reports-tabs'),
                controller: _tabs,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 1.8,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                indicatorColor: ReportsStyle.green,
                dividerColor: NalaraColors.headerDivider,
                labelColor: ReportsStyle.green,
                unselectedLabelColor: ReportsStyle.muted,
                labelStyle: ReportsStyle.tab,
                unselectedLabelStyle: ReportsStyle.tab,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                tabs: [
                  for (var index = 0; index < _statusLabels.length; index++)
                    Tab(
                      key: ValueKey(
                        'reports-tab-${_statusLabels[index].toLowerCase()}',
                      ),
                      height: tabHeight,
                      text: _statusLabels[index],
                    ),
                ],
              );
              return Scaffold(
                backgroundColor: ReportsStyle.cream,
                floatingActionButton:
                    !widget.readOnly && state.value?.items.isNotEmpty == true
                    ? FloatingActionButton.extended(
                        key: const ValueKey('reports-add'),
                        heroTag: 'reports-add',
                        onPressed: () => _open('/teacher/reports/new'),
                        backgroundColor: ReportsStyle.green,
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.add),
                        label: const Text('Tulis laporan'),
                      )
                    : null,
                body: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: NalaraPageLayout(
                        showDivider: false,
                        header: ReportsHeader(
                          loading: state.status == LoadStatus.loading,
                          onBack: () =>
                              finishForm(context, '${widget.routePrefix}/more'),
                          onRefresh: () => _reload(_status, resetPage: true),
                          description:
                              widget.subtitle ??
                              (widget.readOnly
                                  ? 'Lihat laporan perkembangan anak dari Guru.'
                                  : null),
                        ),
                        body: NestedScrollView(
                          key: const ValueKey('reports-scroll'),
                          headerSliverBuilder: (context, innerScrolled) => [
                            SliverOverlapAbsorber(
                              handle:
                                  NestedScrollView.sliverOverlapAbsorberHandleFor(
                                    context,
                                  ),
                              sliver: SliverPersistentHeader(
                                pinned: true,
                                delegate: _ReportsTabs(tabs),
                              ),
                            ),
                          ],
                          body: ScrollConfiguration(
                            behavior: const MaterialScrollBehavior().copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                                PointerDeviceKind.stylus,
                                PointerDeviceKind.invertedStylus,
                              },
                            ),
                            child: TabBarView(
                              key: const ValueKey('reports-tab-view'),
                              controller: _tabs,
                              children: [
                                for (final status in _statuses)
                                  ReportsTabBody(
                                    key: ValueKey(
                                      'reports-body-${status ?? 'all'}',
                                    ),
                                    status: status,
                                    state: _loaders[status]!.state,
                                    onRefresh: () =>
                                        _reload(status, resetPage: true),
                                    onRetry: () => _reload(status),
                                    onAdd: () => _open('/teacher/reports/new'),
                                    readOnly: widget.readOnly,
                                    onOpen: (report) => _open(
                                      '${widget.routePrefix}/reports/${Uri.encodeComponent(report.id)}',
                                    ),
                                    onLoadMore: () {
                                      final loader = _loaders[status]!;
                                      final result = loader.state.value;
                                      if (loader.state.status ==
                                              LoadStatus.loading ||
                                          result == null ||
                                          !result.hasNext) {
                                        return;
                                      }
                                      _pages[status] = result.page + 1;
                                      _reload(status, append: true);
                                    },
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
            },
          ),
    ),
  );
}

class _ReportsTabs extends SliverPersistentHeaderDelegate {
  final TabBar tabs;
  _ReportsTabs(this.tabs);
  @override
  double get minExtent => tabs.preferredSize.height;
  @override
  double get maxExtent => minExtent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(color: ReportsStyle.cream, child: tabs);
  @override
  bool shouldRebuild(covariant _ReportsTabs oldDelegate) =>
      oldDelegate.tabs != tabs;
}

typedef ReportDetailData = ({
  LessonReport report,
  Lesson lesson,
  String studentName,
});

class ReportDetailPage extends StatefulWidget {
  final String id;
  final Future<ReportDetailData> Function(String id)? loadReport;
  final bool readOnly;
  final String routePrefix;
  const ReportDetailPage({
    super.key,
    required this.id,
    this.loadReport,
    this.readOnly = false,
    this.routePrefix = '/teacher',
  }) : assert(!readOnly || loadReport != null);
  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final submit = SubmitCubit();
  @override
  void dispose() {
    submit.close();
    super.dispose();
  }

  Future<ReportDetailData> load() async {
    final loadReport = widget.loadReport;
    if (loadReport != null) return loadReport(widget.id);
    final report = await getIt<ReportsRepository>().get(widget.id);
    final lesson = await getIt<SchedulesRepository>().session(report.sessionId);
    final student = await getIt<StudentsRepository>().get(report.studentId);
    return (report: report, lesson: lesson, studentName: student.name);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ReportDetailStyle.theme(Theme.of(context)),
    child: AsyncPage<ReportDetailData>(
      key: ValueKey((widget.routePrefix, widget.id, widget.loadReport)),
      title: 'Laporan sesi',
      refreshOnCatalogChange: true,
      load: load,
      builder: (context, data, reload) => BlocBuilder<SubmitCubit, SubmitState>(
        bloc: submit,
        builder: (context, state) => ReportDetailContent(
          report: data.report,
          lesson: data.lesson,
          studentName: data.studentName,
          busy: state.busy,
          error: state.error,
          readOnly: widget.readOnly,
          onOpenTarget: (id) => context.push(
            '${widget.routePrefix}/targets/${Uri.encodeComponent(id)}',
          ),
          onOpenSession: () => context.push(
            '${widget.routePrefix}/sessions/${Uri.encodeComponent(data.lesson.id)}',
          ),
          onEdit: widget.readOnly
              ? null
              : () async {
                  await context.push('/teacher/reports/${widget.id}/edit');
                  if (context.mounted) reload();
                },
          onPublish: widget.readOnly
              ? null
              : () => _publish(context, data.report, reload),
        ),
      ),
    ),
  );

  Future<void> _publish(
    BuildContext context,
    LessonReport report,
    VoidCallback reload,
  ) async {
    if (widget.readOnly || submit.state.busy) return;
    final confirmed = await confirmAction(
      context,
      'Terbitkan laporan? Laporan terbit tidak dapat diubah.',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await submit.run(
      () => getIt<ReportsRepository>().publish(report),
    );
    if (ok && context.mounted) {
      successMessage(context, 'Laporan diterbitkan');
      reload();
    }
  }
}

typedef ReportFormData = ({
  Lesson lesson,
  LessonReport? report,
  List<LearningTarget> targets,
});

class ReportFormPage extends StatelessWidget {
  final String? sessionId, reportId;
  const ReportFormPage({super.key, this.sessionId, this.reportId});
  Future<ReportFormData> load() async {
    final report = reportId == null
        ? null
        : await getIt<ReportsRepository>().get(reportId!);
    final lesson = await getIt<SchedulesRepository>().session(
      report?.sessionId ?? sessionId!,
    );
    final targets = <LearningTarget>[];
    var page = 1;
    while (true) {
      final plans = await getIt<LearningRepository>().plans(
        page: page,
        studentId: lesson.studentId,
      );
      for (final plan in plans.items.where(
        (p) => p.subjectId == lesson.subjectId,
      )) {
        final detail = await getIt<LearningRepository>().plan(plan.id);
        targets.addAll(detail.targets);
      }
      if (!plans.hasNext) break;
      page++;
    }
    return (lesson: lesson, report: report, targets: targets);
  }

  @override
  Widget build(BuildContext context) {
    if (sessionId == null && reportId == null) {
      return PagedListPage<Lesson>(
        title: 'Pilih sesi untuk laporan',
        empty: 'Belum ada sesi. Tambahkan jadwal terlebih dahulu.',
        emptyArtwork: 'assets/Empty/Jadwal kosong.png',
        newRoute: '/teacher/schedule/new',
        load: (page) => getIt<SchedulesRepository>().sessions(page: page),
        itemBuilder: (context, lesson, reload) => lesson.status == 'cancelled'
            ? const SizedBox.shrink()
            : LessonCard(
                lesson: lesson,
                onTap: () async {
                  await context.push(
                    '/teacher/reports/new?sessionId=${lesson.id}',
                  );
                  reload();
                },
              ),
      );
    }
    return AsyncPage<ReportFormData>(
      title: reportId == null ? 'Tulis laporan sesi' : 'Edit draft laporan',
      load: load,
      builder: (context, data, _) => _ReportEditor(
        lesson: data.lesson,
        report: data.report,
        targets: data.targets,
      ),
    );
  }
}

class _ReportEditor extends StatefulWidget {
  final Lesson lesson;
  final LessonReport? report;
  final List<LearningTarget> targets;
  const _ReportEditor({
    required this.lesson,
    this.report,
    required this.targets,
  });
  @override
  State<_ReportEditor> createState() => _ReportEditorState();
}

class _ReportEditorState extends State<_ReportEditor> {
  final form = GlobalKey<FormState>(), submit = SubmitCubit();
  late final topic = TextEditingController(text: widget.report?.topic),
      summary = TextEditingController(text: widget.report?.summary),
      observations = TextEditingController(text: widget.report?.observations),
      difficulties = TextEditingController(text: widget.report?.difficulties),
      homework = TextEditingController(text: widget.report?.homework),
      recommendation = TextEditingController(
        text: widget.report?.recommendation,
      );
  late String visibility = widget.report?.visibility ?? 'teacher';
  late final selected = <String>{...?widget.report?.targetIds};
  @override
  void dispose() {
    for (final controller in [
      topic,
      summary,
      observations,
      difficulties,
      homework,
      recommendation,
    ]) {
      controller.dispose();
    }
    submit.close();
    super.dispose();
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLength = 3000,
  }) => FormFieldSpace(
    child: TextFormField(
      controller: controller,
      maxLines: required ? 2 : 3,
      maxLength: maxLength,
      validator: required ? Validators.name : null,
      decoration: InputDecoration(labelText: label),
    ),
  );
  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: PageBody(
      children: [
        DetailRow(
          'Waktu sesi',
          '${DateTimeUtils.full(widget.lesson.startAt)} – ${DateTimeUtils.time(widget.lesson.endAt)}',
        ),
        OutlinedButton(
          onPressed: () async {
            final template = await context.push<ReportTemplate>(
              '/teacher/templates?select=1',
            );
            if (template == null || !context.mounted) return;
            final replace = await confirmAction(
              context,
              'Gunakan template "${template.name}"? Isi topik dan catatan saat ini akan diganti.',
            );
            if (!replace || !mounted) return;
            topic.text = template.topic;
            summary.text = template.summary;
            observations.text = template.observations;
            difficulties.text = template.difficulties;
            homework.text = template.homework;
            recommendation.text = template.recommendation;
          },
          child: const Text('Gunakan template laporan · Pro'),
        ),
        const SizedBox(height: 16),
        field(topic, 'Materi / topik', required: true, maxLength: 200),
        field(summary, 'Ringkasan kegiatan', required: true, maxLength: 5000),
        const SectionTitle('Target yang dievaluasi'),
        if (widget.targets.isEmpty)
          const Text('Belum ada target untuk bidang belajar sesi ini.'),
        ...widget.targets.map(
          (target) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NalaraSurfaceCard(
              key: ValueKey(target.id),
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              onTap: () => setState(() {
                if (!selected.add(target.id)) selected.remove(target.id);
              }),
              child: Row(
                children: [
                  Checkbox(
                    value: selected.contains(target.id),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        selected.add(target.id);
                      } else {
                        selected.remove(target.id);
                      }
                    }),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target.title,
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E292D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${target.progress}% · ${statusLabel(target.status)}',
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 12,
                            color: Color(0xFF7B7F80),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        field(observations, 'Perkembangan yang diamati'),
        field(difficulties, 'Kesulitan yang dialami'),
        field(homework, 'Tugas / latihan lanjutan'),
        field(recommendation, 'Rekomendasi sesi berikutnya'),
        FormFieldSpace(
          child: NalaraDropdown<String>(
            value: visibility,
            decoration: const InputDecoration(labelText: 'Visibilitas laporan'),
            options: ['teacher', 'student', 'shared']
                .map(
                  (value) => NalaraDropdownOption(
                    value: value,
                    label: value == 'teacher'
                        ? 'Hanya Guru'
                        : value == 'student'
                        ? 'Hanya Siswa'
                        : 'Untuk siswa / Orang Tua',
                  ),
                )
                .toList(),
            onChanged: (value) => visibility = value!,
          ),
        ),
        SubmitButton(
          cubit: submit,
          label: 'Simpan draft',
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            LessonReport? saved;
            final ok = await submit.run(() async {
              final draft = ReportDraft(
                topic: topic.text,
                summary: summary.text,
                observations: observations.text,
                difficulties: difficulties.text,
                homework: homework.text,
                recommendation: recommendation.text,
                visibility: visibility,
                targetIds: selected.toList(),
              );
              if (widget.report == null) {
                saved = await getIt<ReportsRepository>().create(
                  widget.lesson.id,
                  draft,
                );
              } else {
                await getIt<ReportsRepository>().update(widget.report!, draft);
                saved = widget.report;
              }
            });
            if (ok && context.mounted) {
              successMessage(context, 'Draft disimpan');
              finishForm(context, '/teacher/reports/${saved!.id}');
            }
          },
        ),
      ],
    ),
  );
}
