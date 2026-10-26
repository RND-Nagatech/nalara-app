import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/errors/app_failure.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/session_overview.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_timing.dart';
import '../widgets/lesson_clock.dart';
import '../widgets/lesson_status.dart';
import '../../domain/repositories/schedules_repository.dart';
import '../../domain/repositories/schedule_repeat_repository.dart';
import '../widgets/session_cancellation_dialog.dart';
import '../../domain/usecases/load_session_overview.dart';
import '../widgets/session_action_cards.dart';
import '../widgets/session_detail_style.dart';
import '../widgets/session_summary_card.dart';
import '../widgets/group_attendance_card.dart';
import '../widgets/session_participant_picker.dart';
import '../../../teaching_guide/presentation/session_teaching_guide.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';

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
  bool _confirming = false;
  bool _rescheduleSubmitted = false;

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
    _confirming = false;
    _rescheduleSubmitted = false;
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
    if (!_submit.state.busy && !_confirming) await _loader.load();
  }

  Future<void> _saveGroupAttendance(List<AttendanceSelection> entries) async {
    if (widget.readOnly || _submit.state.busy || _confirming) return;
    if (!_attendanceReady()) return;
    final loader = _loader;
    final id = widget.id;
    setState(() => _confirming = true);
    final confirmed = await confirmAction(
      context,
      'Simpan presensi untuk ${entries.length} siswa? Status yang disimpan akan dikunci. Siswa yang belum dipilih tidak akan diubah.',
    );
    if (!mounted || !identical(loader, _loader)) return;
    setState(() => _confirming = false);
    if (!confirmed || !_visible || !_attendanceReady()) return;
    await _run(
      () => getIt<SchedulesRepository>().attendanceBatch(id, entries),
      'Presensi kelompok disimpan',
    );
  }

  Future<void> _createReport(Lesson lesson) async {
    if (widget.readOnly || _submit.state.busy || _confirming) return;
    final loader = _loader;
    setState(() => _confirming = true);
    final ids = await chooseReportSessions(
      context,
      lesson,
      existingSessionIds:
          _loader.state.value?.reports
              .map((report) => report.sessionId)
              .toSet() ??
          const {},
    );
    if (!mounted || !identical(loader, _loader)) return;
    setState(() => _confirming = false);
    if (ids != null && ids.isNotEmpty && _visible) {
      await _open(reportFormLocation(ids, routePrefix: widget.routePrefix));
    }
  }

  Future<void> _saveAttendance(BuildContext context, String attendance) async {
    final id = widget.id;
    if (widget.readOnly || _submit.state.busy || _confirming) return;
    if (attendance == 'cancelled') {
      await _cancel(context);
      return;
    }
    if (!_attendanceReady()) return;
    await _run(
      () => getIt<SchedulesRepository>().attendance(id, attendance),
      'Presensi disimpan',
    );
  }

  bool _attendanceReady() {
    final lesson = _loader.state.value?.lesson;
    if (lesson == null) return false;
    if (!LessonTiming.attendanceAvailable(lesson, DateTime.now())) {
      if (_visible) {
        errorMessage(context, 'Presensi tersedia saat sesi dimulai.');
      }
      return false;
    }
    return true;
  }

  Future<void> _cancel(BuildContext context) async {
    final id = widget.id;
    if (widget.readOnly || _submit.state.busy || _confirming) return;
    final data = _loader.state.value;
    if (data == null || data.lesson.status == 'cancelled') return;
    final loader = _loader;
    final repeating =
        data.schedule.recurrence == 'weekly' &&
        data.lesson.startAt.isAfter(DateTime.now());
    final auth = getIt.isRegistered<AuthCubit>() ? getIt<AuthCubit>() : null;
    final actor = auth?.state.teacher;
    bool sameActor() =>
        auth == null ||
        (auth.state.status == AuthStatus.authenticated &&
            identical(auth.state.teacher, actor));
    setState(() => _confirming = true);
    final confirmed = await showSessionCancellationDialog(
      context,
      allowFollowing: repeating,
      group: data.lesson.isGroup,
      onSubmit: (scope, reason) async {
        if (!mounted ||
            !identical(loader, _loader) ||
            widget.id != id ||
            widget.readOnly ||
            !sameActor()) {
          throw const AppFailure(
            'Halaman sesi berubah. Buka kembali sesi yang akan dibatalkan.',
          );
        }
        await (scope == SessionCancellationScope.following
            ? getIt<ScheduleRepeatRepository>().cancelFollowing(id, reason)
            : getIt<SchedulesRepository>().cancelSession(id, reason));
        if (mounted && identical(loader, _loader) && sameActor()) {
          await loader.load();
        }
      },
    );
    if (!mounted || !context.mounted || !identical(loader, _loader)) return;
    setState(() => _confirming = false);
    if (confirmed == true && _visible) {
      successMessage(
        context,
        'Pertemuan dibatalkan. Alasan dapat dilihat Siswa dan Orang Tua.',
      );
    }
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
    if (request == null ||
        submit.state.busy ||
        !_visible ||
        _rescheduleSubmitted ||
        data.reschedulePending == true) {
      return;
    }
    var submitted = false;
    final ok = await submit.run(() async {
      submitted = await request(context, data);
    });
    if (!mounted || !context.mounted || !identical(loader, _loader)) return;
    if (ok && submitted) setState(() => _rescheduleSubmitted = true);
    if (_visible) {
      if (!ok && submit.state.error != null) {
        errorMessage(context, submit.state.error!);
      } else if (submitted) {
        successMessage(context, 'Permintaan perubahan jadwal sedang diproses.');
      }
    }
    if (ok && submitted) await loader.load();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: LessonClockScope(
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
                      NalaraHeader(
                        child: _header(context, submit.busy || _confirming),
                      ),
                      Expanded(
                        child:
                            BlocConsumer<
                              LoadCubit<SessionOverview>,
                              LoadState<SessionOverview>
                            >(
                              bloc: _loader,
                              listener: (context, state) {
                                if (state.status == LoadStatus.success &&
                                    state.value?.reschedulePending != null &&
                                    _rescheduleSubmitted) {
                                  setState(() => _rescheduleSubmitted = false);
                                }
                              },
                              builder: (context, state) => LessonClockBuilder(
                                builder: (context, now) => _body(
                                  context,
                                  state,
                                  submit.busy || _confirming,
                                  now,
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
    DateTime now,
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
    final attendanceReady = LessonTiming.attendanceAvailable(lesson, now);
    final unavailableReason = attendanceReady
        ? null
        : 'Presensi tersedia saat sesi dimulai.';
    final reschedulePending =
        _rescheduleSubmitted || data.reschedulePending == true;
    final canRequestReschedule =
        !reschedulePending && lesson.startAt.isAfter(now);
    final reported = data.reports.map((report) => report.sessionId).toSet();
    final canCreateReport = lesson.isGroup
        ? lesson.participants.any(
            (p) => p.status != 'cancelled' && !reported.contains(p.sessionId),
          )
        : data.reports.isEmpty;
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LessonStatus(timing: LessonTiming.at(lesson, now)),
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
            if (!widget.readOnly && lesson.isGroup)
              GroupAttendanceCard(
                key: ValueKey('group-attendance-${lesson.id}'),
                participants: lesson.participants,
                busy: busy,
                unavailableReason: unavailableReason,
                onSave: enabled && attendanceReady
                    ? _saveGroupAttendance
                    : null,
                onStudent: enabled
                    ? (p) => _open(
                        '${widget.routePrefix}/students/${Uri.encodeComponent(p.studentId)}',
                      )
                    : null,
              )
            else if (lesson.status != 'cancelled')
              SessionAttendanceCard(
                key: ValueKey('session-attendance-${lesson.id}'),
                attendance: lesson.attendance,
                busy: busy,
                readOnly: widget.readOnly,
                unavailableReason: unavailableReason,
                onSave: enabled && !widget.readOnly && attendanceReady
                    ? (value) => _saveAttendance(context, value)
                    : null,
              ),
            if (lesson.status == 'scheduled' &&
                lesson.canManageTime &&
                (!widget.readOnly || widget.onRequestReschedule != null))
              SessionSectionCard(
                key: const ValueKey('session-manage-card'),
                title: 'Kelola sesi',
                children: [
                  if (widget.readOnly) ...[
                    SessionActionTile(
                      key: const ValueKey('session-request-reschedule'),
                      label: reschedulePending
                          ? 'Permintaan sedang diproses'
                          : 'Minta ganti tanggal',
                      description: reschedulePending
                          ? 'Pengajuan baru tersedia setelah permintaan ini selesai atau dibatalkan. Lihat status atau tanggapi tawaran di daftar permintaan.'
                          : !canRequestReschedule
                          ? 'Sesi yang sudah dimulai tidak dapat diajukan ulang.'
                          : 'Pilih waktu tersedia dan kirim permintaan ke Guru.',
                      onPressed: enabled && canRequestReschedule
                          ? () => _requestReschedule(context, data)
                          : null,
                    ),
                    if (reschedulePending)
                      TextButton(
                        key: const ValueKey('session-view-reschedule-requests'),
                        onPressed: enabled
                            ? () => _open(
                                '${widget.routePrefix}/reschedule-requests',
                              )
                            : null,
                        child: const Text('Lihat permintaan jadwal'),
                      ),
                  ] else ...[
                    SessionActionTile(
                      key: const ValueKey('session-reschedule'),
                      label: 'Ubah waktu pertemuan ini',
                      description: lesson.isGroup
                          ? 'Atur ulang waktu untuk seluruh peserta pertemuan ini.'
                          : 'Atur ulang tanggal dan waktu sesi.',
                      onPressed: enabled
                          ? () =>
                                _open('${widget.routePrefix}/sessions/$id/edit')
                          : null,
                    ),
                    const SizedBox(height: 10),
                    SessionActionTile(
                      key: const ValueKey('session-cancel'),
                      label: 'Batalkan pertemuan',
                      description: lesson.isGroup
                          ? 'Batalkan pertemuan ini untuk seluruh peserta.'
                          : 'Sesi akan dibatalkan dan tidak dihitung.',
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
              canCreate: canCreateReport,
              onCreate: enabled && !widget.readOnly
                  ? () => _createReport(lesson)
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
