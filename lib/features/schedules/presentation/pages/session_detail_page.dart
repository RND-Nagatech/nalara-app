import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/session_overview.dart';
import '../../domain/repositories/schedules_repository.dart';
import '../../domain/usecases/load_session_overview.dart';
import '../widgets/session_action_cards.dart';
import '../widgets/session_detail_style.dart';
import '../widgets/session_summary_card.dart';
import '../../../teaching_guide/presentation/session_teaching_guide.dart';

typedef SessionOverviewLoader = Future<SessionOverview> Function(String id);
typedef SessionRescheduleRequest =
    Future<bool> Function(BuildContext context, SessionOverview data);

class SessionDetailPage extends StatefulWidget {
  final String id;
  final SessionOverviewLoader? loadOverview;
  final bool readOnly, allowSeriesNavigation;
  final String routePrefix;
  final String? studentRoute;
  final SessionRescheduleRequest? onRequestReschedule;

  const SessionDetailPage({
    super.key,
    required this.id,
    this.loadOverview,
    this.readOnly = false,
    this.routePrefix = '/teacher',
    this.studentRoute,
    this.allowSeriesNavigation = true,
    this.onRequestReschedule,
  }) : assert(!readOnly || loadOverview != null);

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage>
    with TeachingCatalogRefresh<SessionDetailPage> {
  late LoadCubit<SessionOverview> _loader;
  late SubmitCubit _submit;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    final id = widget.id;
    final loadOverview =
        widget.loadOverview ?? getIt<LoadSessionOverview>().call;
    _loader = LoadCubit<SessionOverview>(() => loadOverview(id))..load();
    _submit = SubmitCubit();
  }

  @override
  void onTeachingCatalogChanged() => _loader.load();

  @override
  void didUpdateWidget(covariant SessionDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.loadOverview != widget.loadOverview ||
        oldWidget.readOnly != widget.readOnly ||
        oldWidget.routePrefix != widget.routePrefix) {
      _loader.close();
      _submit.close();
      _bind();
    }
  }

  @override
  void dispose() {
    _loader.close();
    _submit.close();
    super.dispose();
  }

  Future<void> _open(String route) async {
    if (_submit.state.busy) return;
    final loader = _loader;
    await context.push(route);
    if (mounted && identical(loader, _loader)) await loader.load();
  }

  Future<void> _refresh() async {
    if (!_submit.state.busy) await _loader.load();
  }

  Future<void> _saveAttendance(BuildContext context, String attendance) async {
    final id = widget.id;
    if (widget.readOnly || _submit.state.busy) return;
    if (attendance == 'cancelled') {
      final confirmed = await confirmAction(context, 'Batalkan sesi ini?');
      if (!confirmed || !mounted || !context.mounted || widget.id != id) return;
    }
    await _run(
      () => getIt<SchedulesRepository>().attendance(id, attendance),
      'Presensi disimpan',
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final id = widget.id;
    if (widget.readOnly || _submit.state.busy) return;
    final confirmed = await confirmAction(
      context,
      'Batalkan pertemuan ini saja? Sesi lain pada seri ini tidak berubah.',
    );
    if (!confirmed || !mounted || !context.mounted || widget.id != id) return;
    await _run(
      () => getIt<SchedulesRepository>().cancelSession(id),
      'Pertemuan dibatalkan',
    );
  }

  Future<void> _run(Future<void> Function() operation, String success) async {
    final loader = _loader, submit = _submit;
    if (widget.readOnly || submit.state.busy) return;
    final ok = await submit.run(operation);
    if (!mounted || !identical(loader, _loader)) return;
    if (_visible) {
      if (ok) {
        successMessage(context, success);
      } else if (submit.state.error != null) {
        errorMessage(context, submit.state.error!);
      }
    }
    if (ok) await loader.load();
  }

  bool get _visible {
    final router = GoRouter.maybeOf(context);
    return (ModalRoute.of(context)?.isCurrent ?? true) &&
        (router == null ||
            router.state.uri.path ==
                '${widget.routePrefix}/sessions/${Uri.encodeComponent(widget.id)}');
  }

  Future<void> _requestReschedule(
    BuildContext context,
    SessionOverview data,
  ) async {
    final request = widget.onRequestReschedule;
    final loader = _loader, submit = _submit;
    if (request == null || submit.state.busy || !_visible) return;
    var submitted = false;
    final ok = await submit.run(() async {
      submitted = await request(context, data);
    });
    if (!mounted || !context.mounted || !identical(loader, _loader)) return;
    if (_visible) {
      if (!ok && submit.state.error != null) {
        errorMessage(context, submit.state.error!);
      } else if (submitted) {
        successMessage(
          context,
          'Permintaan perubahan jadwal sudah dikirim ke Guru.',
        );
      }
    }
    if (ok && submitted) await loader.load();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: SessionDetailStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: SessionDetailStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: BlocBuilder<SubmitCubit, SubmitState>(
                bloc: _submit,
                builder: (context, submit) => Column(
                  children: [
                    NalaraHeader(child: _header(context, submit.busy)),
                    Expanded(
                      child:
                          BlocBuilder<
                            LoadCubit<SessionOverview>,
                            LoadState<SessionOverview>
                          >(
                            bloc: _loader,
                            builder: (context, state) =>
                                _body(context, state, submit.busy),
                          ),
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

  Widget _header(BuildContext context, bool busy) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('session-back'),
          tooltip: 'Kembali ke jadwal',
          onPressed: busy
              ? null
              : () => finishForm(context, '${widget.routePrefix}/schedule'),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: SessionDetailStyle.green,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text('Detail sesi', style: SessionDetailStyle.title),
        ),
      ],
    ),
  );

  Widget _body(
    BuildContext context,
    LoadState<SessionOverview> state,
    bool busy,
  ) {
    if (state.status == LoadStatus.error) {
      return ErrorNotice(
        state.error!,
        title: 'Sesi belum dapat dimuat',
        retry: _refresh,
        retryKey: const ValueKey('session-retry'),
      );
    }
    if (state.value == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = state.value!;
    final lesson = data.lesson;
    final enabled = !busy && state.status == LoadStatus.success;
    final id = Uri.encodeComponent(lesson.id);
    return RefreshIndicator(
      color: SessionDetailStyle.green,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        key: PageStorageKey('session-detail-${lesson.id}'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.status == LoadStatus.loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            SessionSummaryCard(
              showTeacher: widget.routePrefix == '/student',
              showSeries: widget.allowSeriesNavigation,
              key: const ValueKey('session-summary-card'),
              data: data,
              onStudent: enabled
                  ? () => _open(
                      widget.studentRoute ??
                          '${widget.routePrefix}/students/${Uri.encodeComponent(lesson.studentId)}',
                    )
                  : null,
              onSeries: enabled && widget.allowSeriesNavigation
                  ? () => _open(
                      '${widget.routePrefix}/schedule/${Uri.encodeComponent(lesson.scheduleId)}',
                    )
                  : null,
            ),
            if (!widget.readOnly &&
                widget.routePrefix == '/teacher' &&
                lesson.status != 'cancelled')
              SessionTeachingGuide(
                key: const ValueKey('session-teaching-guide'),
                attendanceRecorded: lesson.attendance != 'pending',
                reportPublished: data.reports.any(
                  (report) => report.status == 'published',
                ),
              ),
            if (lesson.status != 'cancelled')
              SessionAttendanceCard(
                key: ValueKey('session-attendance-${lesson.id}'),
                attendance: lesson.attendance,
                busy: busy,
                readOnly: widget.readOnly,
                onSave: enabled && !widget.readOnly
                    ? (value) => _saveAttendance(context, value)
                    : null,
              ),
            if (lesson.status == 'scheduled' &&
                (!widget.readOnly || widget.onRequestReschedule != null))
              SessionSectionCard(
                key: const ValueKey('session-manage-card'),
                title: 'Kelola sesi',
                children: [
                  if (widget.readOnly)
                    SessionActionTile(
                      key: const ValueKey('session-request-reschedule'),
                      label: 'Minta ganti tanggal',
                      description:
                          'Pilih waktu tersedia dan kirim permintaan ke Guru.',
                      onPressed: enabled
                          ? () => _requestReschedule(context, data)
                          : null,
                    )
                  else ...[
                    SessionActionTile(
                      key: const ValueKey('session-reschedule'),
                      label: 'Ubah waktu pertemuan ini',
                      description: 'Atur ulang tanggal dan waktu sesi.',
                      onPressed: enabled
                          ? () =>
                                _open('${widget.routePrefix}/sessions/$id/edit')
                          : null,
                    ),
                    const SizedBox(height: 10),
                    SessionActionTile(
                      key: const ValueKey('session-cancel'),
                      label: 'Batalkan pertemuan',
                      description: 'Sesi akan dibatalkan dan tidak dihitung.',
                      destructive: true,
                      onPressed: enabled ? () => _cancel(context) : null,
                    ),
                  ],
                ],
              ),
            SessionReportsCard(
              key: const ValueKey('session-reports-card'),
              reports: data.reports,
              cancelled: lesson.status == 'cancelled',
              readOnly: widget.readOnly,
              onCreate: enabled && !widget.readOnly
                  ? () =>
                        _open('${widget.routePrefix}/reports/new?sessionId=$id')
                  : null,
              onOpen: enabled
                  ? (report) => _open(
                      '${widget.routePrefix}/reports/${Uri.encodeComponent(report.id)}',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
