import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/domain/page.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_load_more.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../access/presentation/widgets/referral_invitation_widgets.dart';
import '../../../learning_goals/domain/usecases/update_progress.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_overview.dart';
import '../../domain/repositories/students_repository.dart';
import '../../domain/usecases/load_student_overview.dart';
import '../widgets/student_detail_style.dart';
import '../widgets/student_profile_card.dart';
import '../widgets/student_detail_tabs.dart';
import '../widgets/student_summary_cards.dart';
import '../bloc/student_detail_cubit.dart';

class StudentDetailPage extends StatefulWidget {
  final String id;
  final StudentOverviewLoader? loader;
  final bool readOnly;
  final String routePrefix;
  const StudentDetailPage({
    super.key,
    required this.id,
    this.loader,
    this.readOnly = false,
    this.routePrefix = '/teacher',
  }) : assert(!readOnly || loader != null);
  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage>
    with
        SingleTickerProviderStateMixin,
        TeachingCatalogRefresh<StudentDetailPage> {
  late StudentDetailCubit _loader;
  late final TabController _tabs;
  late SubmitCubit _submit;
  String? _action;
  @override
  void onTeachingCatalogChanged() => _loader.refresh();
  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: widget.readOnly ? 5 : StudentDetailTab.values.length,
      vsync: this,
    );
    _bind();
  }

  void _bind() {
    final id = widget.id;
    _loader = StudentDetailCubit(
      widget.loader ?? getIt<LoadStudentOverview>(),
      id,
    )..load();
    _submit = SubmitCubit();
    _action = null;
  }

  @override
  void didUpdateWidget(covariant StudentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loader.close();
      _submit.close();
      _tabs.index = 0;
      _bind();
    }
  }

  @override
  void dispose() {
    _loader.close();
    _submit.close();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _open(String route) async {
    final loader = _loader;
    await context.push(route);
    if (mounted && identical(loader, _loader)) await loader.refresh();
  }

  Future<bool> _run(String action, Future<void> Function() operation) async {
    final submit = _submit;
    if (submit.state.busy) return false;
    setState(() => _action = action);
    final ok = await submit.run(operation);
    if (!mounted || !identical(submit, _submit)) return false;
    final router = GoRouter.maybeOf(context);
    final visible =
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        (router == null ||
            router.state.uri.path ==
                '/teacher/students/${Uri.encodeComponent(widget.id)}');
    if (!visible ||
        (action == 'create-code' &&
            _tabs.index != StudentDetailTab.referral.index)) {
      if (ok) await _loader.refresh();
      return false;
    }
    if (!ok && submit.state.error != null) {
      errorMessage(context, submit.state.error!);
    }
    return ok;
  }

  Future<void> _createCode() async {
    final id = widget.id;
    ParentInvitation? invitation;
    final ok = await _run('create-code', () async {
      invitation = await getIt<StudentsRepository>().invite(id);
    });
    if (ok && mounted) {
      _loader.refresh();
      await showReferralCode(
        context,
        invitation!,
        title: 'Kode referral Siswa',
      );
    }
  }

  Future<void> _revokeCode(ParentInvitation invitation) async {
    final id = widget.id;
    final confirmed = await confirmAction(
      context,
      'Cabut kode ini? Akses Siswa yang sudah terhubung tetap aktif.',
    );
    if (!confirmed || !mounted || widget.id != id) return;
    final ok = await _run(
      'revoke-code',
      () => getIt<StudentsRepository>().revoke(id, invitation.id),
    );
    if (ok) await _loader.refresh();
  }

  Future<void> _revokeAccess() async {
    final id = widget.id;
    final confirmed = await confirmAction(
      context,
      'Cabut akses Siswa ini pada seluruh perangkat dan semua kodenya? Data siswa tidak dihapus.',
    );
    if (!confirmed || !mounted || widget.id != id) return;
    final ok = await _run(
      'revoke-access',
      () => getIt<StudentsRepository>().revokeAccess(id),
    );
    if (ok && mounted) {
      successMessage(context, 'Akses Siswa dicabut');
      await _loader.refresh();
    }
  }

  Future<void> _archive(Student student) async {
    final id = widget.id;
    final confirmed = await confirmAction(
      context,
      'Arsipkan ${student.name}? Data dan riwayat tetap tersimpan.',
    );
    if (!confirmed || !mounted || widget.id != id) return;
    final ok = await _run(
      'archive',
      () => getIt<StudentsRepository>().archive(id),
    );
    if (ok && mounted) {
      successMessage(context, 'Siswa diarsipkan');
      await _loader.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: StudentDetailStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: StudentDetailStyle.cream,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              NalaraHeader(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 18, 10),
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('student-detail-back'),
                        tooltip: 'Kembali ke siswa',
                        onPressed: () => finishForm(
                          context,
                          '${widget.routePrefix}/students',
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: StudentDetailStyle.green,
                          minimumSize: const Size(40, 40),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 25),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Detail siswa',
                          style: TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 16,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            color: StudentDetailStyle.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<StudentDetailCubit, StudentDetailState>(
                  bloc: _loader,
                  builder: (context, state) {
                    if (state.data == null) {
                      return ListView(
                        key: ValueKey('student-detail-scroll-${widget.id}'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (state.error != null)
                            ErrorNotice(state.error!, retry: _loader.load)
                          else
                            const Padding(
                              padding: EdgeInsets.all(72),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      );
                    }
                    return BlocBuilder<SubmitCubit, SubmitState>(
                      bloc: _submit,
                      builder: (context, submit) =>
                          _content(state.data!, state, submit),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _content(
    StudentOverview data,
    StudentDetailState state,
    SubmitState submit,
  ) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: RefreshIndicator(
        color: StudentDetailStyle.green,
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.vertical,
        onRefresh: _loader.refresh,
        child: NestedScrollView(
          key: ValueKey('student-detail-scroll-${widget.id}'),
          headerSliverBuilder: (context, innerScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: StudentProfileCard(
                  key: const ValueKey('student-profile-card'),
                  student: data.student,
                  showInternalNotes: !widget.readOnly,
                  onEdit: widget.readOnly
                      ? null
                      : () => _open(
                          '/teacher/students/${Uri.encodeComponent(data.student.id)}/edit',
                        ),
                ),
              ),
            ),
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: StudentDetailTabs(
                  controller: _tabs,
                  height: MediaQuery.textScalerOf(context).scale(12) * 1.5 + 32,
                  labels: widget.readOnly
                      ? studentDetailTabLabels.take(5).toList()
                      : studentDetailTabLabels,
                ),
              ),
            ),
          ],
          body: TabBarView(
            key: const ValueKey('student-detail-tab-view'),
            controller: _tabs,
            children: [
              for (final tab in StudentDetailTab.values.take(
                widget.readOnly ? 5 : 6,
              ))
                Builder(
                  builder: (context) => CustomScrollView(
                    key: PageStorageKey(
                      'student-detail-${widget.id}-${tab.name}',
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          14,
                          10,
                          14,
                          24 + MediaQuery.paddingOf(context).bottom,
                        ),
                        sliver: SliverList.list(
                          children: [
                            if (state.loading) const LinearProgressIndicator(),
                            if (state.error != null)
                              ErrorNotice(state.error!, retry: _loader.load),
                            _section(tab, data, submit),
                            if (tab == StudentDetailTab.plans)
                              _pager(data.planPage, tab, state.loading),
                            if (tab == StudentDetailTab.sessions)
                              _pager(data.lessonPage, tab, state.loading),
                            if (tab == StudentDetailTab.reports)
                              _pager(data.reportPage, tab, state.loading),
                          ],
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
  );

  Widget _section(
    StudentDetailTab tab,
    StudentOverview data,
    SubmitState submit,
  ) {
    final id = Uri.encodeComponent(data.student.id);
    final active = !widget.readOnly && data.student.status == 'active';
    return switch (tab) {
      StudentDetailTab.summary => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudentSummaryCards(
            summary: data.summary,
            onTargets: () => _tabs.animateTo(StudentDetailTab.plans.index),
          ),
          if (!widget.readOnly)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _open('/teacher/analytics?studentId=$id'),
                child: const Text('Lihat analitik lengkap · Pro'),
              ),
            ),
          if (active)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  if (submit.error != null && _action == 'archive')
                    Text(
                      submit.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  TextButton(
                    key: const ValueKey('student-archive'),
                    onPressed: submit.busy
                        ? null
                        : () => _archive(data.student),
                    child: const Text('Arsipkan siswa'),
                  ),
                ],
              ),
            ),
        ],
      ),
      StudentDetailTab.plans => StudentSectionCard(
        key: const ValueKey('student-plans-card'),
        title: 'Target & bidang belajar',
        children: [
          if (data.plans.isEmpty)
            const Text(
              'Belum ada rencana belajar untuk siswa ini.',
              style: StudentDetailStyle.body,
            ),
          for (final plan in data.plans)
            _related(
              key: ValueKey('student-plan-${plan.id}'),
              title: plan.title,
              subtitle:
                  '${plan.subjectName}\n${getIt<PlanProgressLabel>()(plan)} · ${DateTimeUtils.date(plan.startAt)} – ${DateTimeUtils.date(plan.endAt)}',
              route:
                  '${widget.routePrefix}/plans/${Uri.encodeComponent(plan.id)}',
            ),
          if (active) ...[
            const SizedBox(height: 8),
            StudentSoftButton(
              key: const ValueKey('student-create-plan'),
              label: 'Buat rencana belajar',
              onPressed: () => _open('/teacher/targets/new?studentId=$id'),
            ),
          ],
        ],
      ),
      StudentDetailTab.sessions => StudentSectionCard(
        key: const ValueKey('student-sessions-card'),
        title: 'Riwayat sesi',
        children: [
          if (data.lessons.isEmpty)
            const Text('Belum ada sesi les.', style: StudentDetailStyle.body),
          for (final lesson in data.lessons)
            _related(
              key: ValueKey('student-session-${lesson.id}'),
              title: DateTimeUtils.full(lesson.startAt),
              subtitle:
                  '${statusLabel(lesson.status)} · ${statusLabel(lesson.attendance)}',
              route:
                  '${widget.routePrefix}/sessions/${Uri.encodeComponent(lesson.id)}',
            ),
        ],
      ),
      StudentDetailTab.reports => StudentSectionCard(
        key: const ValueKey('student-reports-card'),
        title: 'Laporan belajar',
        children: [
          if (data.reports.isEmpty)
            const Text(
              'Belum ada laporan sesi.',
              style: StudentDetailStyle.body,
            ),
          for (final report in data.reports)
            _related(
              key: ValueKey('student-report-${report.id}'),
              title: report.topic,
              subtitle: statusLabel(report.status),
              route:
                  '${widget.routePrefix}/reports/${Uri.encodeComponent(report.id)}',
            ),
        ],
      ),
      StudentDetailTab.family => StudentSectionCard(
        key: const ValueKey('student-family-card'),
        title: 'Orang Tua & keluarga',
        children: [
          if (widget.readOnly) ...[
            Text(
              data.family?.name ?? 'Keluarga belum tersedia',
              style: StudentDetailStyle.title,
            ),
            const SizedBox(height: 8),
            Text(
              'Orang Tua: ${data.family?.parentName ?? '—'}',
              style: StudentDetailStyle.body,
            ),
            const SizedBox(height: 8),
            Text(
              'Nomor HP: ${data.family?.parentPhone ?? '—'}',
              style: StudentDetailStyle.body,
            ),
          ] else ...[
            const Text(
              'Kode Orang Tua dibuat per keluarga, bukan per anak. Hubungkan saudara kandung ke keluarga yang sama.',
              style: StudentDetailStyle.body,
            ),
            const SizedBox(height: 8),
            StudentSoftButton(
              key: const ValueKey('student-open-family'),
              label: data.student.familyId == null
                  ? 'Kelola Orang Tua & keluarga'
                  : 'Buka keluarga siswa',
              onPressed: () => _open(
                data.student.familyId == null
                    ? '/teacher/families'
                    : '/teacher/families/${Uri.encodeComponent(data.student.familyId!)}',
              ),
            ),
          ],
        ],
      ),
      StudentDetailTab.referral => StudentSectionCard(
        key: const ValueKey('student-referral-card'),
        title: 'Kode referral Siswa',
        children: [
          const Text(
            'Kode berlaku 7 hari, hanya dapat digunakan sekali, dan hanya ditampilkan saat dibuat. Kode baru menggantikan kode lama yang belum dipakai.',
            style: StudentDetailStyle.body,
          ),
          for (final invitation in data.invitations)
            ReferralInvitationTile(
              key: ValueKey(invitation.id),
              invitation: invitation,
              onRevoke: () {
                if (!submit.busy) _revokeCode(invitation);
              },
            ),
          if (submit.error != null && _action != 'archive')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  submit.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (active) ...[
            FilledButton(
              key: const ValueKey('student-create-code'),
              onPressed: submit.busy ? null : _createCode,
              child: submit.busy && _action == 'create-code'
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Buat kode referral Siswa',
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            key: const ValueKey('student-revoke-access'),
            onPressed: submit.busy ? null : _revokeAccess,
            child: const Text(
              'Cabut seluruh akses Siswa',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    };
  }

  Widget _pager<T>(PageResult<T> page, StudentDetailTab tab, bool loading) {
    if (!page.hasNext) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: NalaraLoadMoreButton(
        buttonKey: ValueKey('student-${tab.name}-load-more'),
        hasMore: page.hasNext,
        loading: loading,
        onPressed: () => _loader.loadMore(tab),
      ),
    );
  }

  Widget _related({
    required Key key,
    required String title,
    required String subtitle,
    required String route,
  }) => Semantics(
    button: true,
    child: Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: StudentDetailStyle.body.copyWith(
                        color: StudentDetailStyle.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: StudentDetailStyle.body),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: StudentDetailStyle.green,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
