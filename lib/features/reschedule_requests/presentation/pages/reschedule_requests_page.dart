import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../shared/widgets/nalara_load_more.dart';
import '../../../../shared/widgets/nalara_page_header.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/reschedule_request.dart';
import '../../domain/repositories/reschedule_requests_repository.dart';
import '../bloc/reschedule_requests_cubit.dart';
import '../widgets/reschedule_proposal_sheet.dart';
import '../widgets/reschedule_request_card.dart';

typedef RescheduleRequestAction =
    Future<void> Function(RescheduleRequest request, String action);

class RescheduleRequestsPage extends StatefulWidget {
  final bool parent;
  final String? timezone;
  final RescheduleRequestsLoader? loadRequests;
  final RescheduleRequestAction? onAction;
  final Map<String, String> studentNames, studentGrades;

  const RescheduleRequestsPage({
    super.key,
    this.parent = false,
    this.timezone,
    this.loadRequests,
    this.onAction,
    this.studentNames = const {},
    this.studentGrades = const {},
  }) : assert(!parent || (loadRequests != null && onAction != null));

  @override
  State<RescheduleRequestsPage> createState() => _RescheduleRequestsPageState();
}

class _RescheduleRequestsPageState extends State<RescheduleRequestsPage> {
  late RescheduleRequestsCubit _cubit;
  late RescheduleRequestAction _action;
  RescheduleRequestsRepository? _teacherRepository;

  String get _prefix => widget.parent ? '/parent' : '/teacher';
  String get _timezone =>
      widget.timezone ??
      (getIt.isRegistered<AuthCubit>()
          ? getIt<AuthCubit>().state.teacher?.timezone
          : null) ??
      DateTimeUtils.zone;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _teacherRepository = widget.parent
        ? null
        : getIt<RescheduleRequestsRepository>();
    final repository = _teacherRepository;
    _action =
        widget.onAction ??
        (request, action) => repository!.review(request.id, action);
    _cubit = RescheduleRequestsCubit(
      widget.loadRequests ??
          (page) => repository!.list(page: page, status: 'pending'),
    )..refresh();
  }

  @override
  void didUpdateWidget(covariant RescheduleRequestsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parent != widget.parent ||
        oldWidget.loadRequests != widget.loadRequests ||
        oldWidget.onAction != widget.onAction ||
        oldWidget.timezone != widget.timezone) {
      _cubit.close();
      _bind();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  bool _sameSource(RescheduleRequestsCubit cubit) {
    if (!mounted || !identical(cubit, _cubit)) return false;
    final router = GoRouter.maybeOf(context);
    return router == null ||
        router.state.uri.path == '$_prefix/reschedule-requests';
  }

  Future<void> _act(RescheduleRequest request, String action) async {
    final cubit = _cubit;
    final repository = _teacherRepository;
    final operation = _action;
    if (!_sameSource(cubit) ||
        !cubit.state.canAct ||
        request.status != 'pending') {
      return;
    }
    final changed = await cubit.perform(request.id, () async {
      if (action == 'proposed') {
        return await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              isDismissible: false,
              enableDrag: false,
              showDragHandle: true,
              backgroundColor: RescheduleRequestsStyle.cream,
              builder: (_) => RescheduleProposalSheet(
                request: request,
                timezone: _timezone,
                repository: repository!,
                isCurrent: () => _sameSource(cubit),
              ),
            ) ??
            false;
      }
      final message = switch (action) {
        'approved' => 'Setujui waktu yang diminta dan pindahkan sesi ini?',
        'rejected' => 'Tolak permintaan perubahan jadwal ini?',
        'cancel' => 'Batalkan permintaan perubahan jadwal ini?',
        'accept' => 'Terima tawaran waktu dari Guru dan pindahkan sesi ini?',
        'decline' => 'Tolak tawaran waktu dari Guru?',
        _ => '',
      };
      final confirmed = await confirmAction(context, message);
      if (!confirmed || !mounted || !_sameSource(cubit)) return false;
      await operation(request, action);
      return true;
    });
    if (!mounted || !_sameSource(cubit)) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    if (changed) {
      successMessage(context, switch (action) {
        'approved' => 'Perubahan jadwal disetujui.',
        'rejected' => 'Perubahan jadwal ditolak.',
        'proposed' => 'Tawaran waktu sudah dikirim ke Orang Tua.',
        'cancel' => 'Permintaan perubahan jadwal dibatalkan.',
        'accept' => 'Tawaran waktu diterima.',
        _ => 'Tawaran waktu ditolak.',
      });
    } else if (cubit.state.actionError != null) {
      errorMessage(context, cubit.state.actionError!);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RescheduleRequestsCubit, RescheduleRequestsState>(
        bloc: _cubit,
        builder: (context, state) => PopScope(
          canPop: state.activeRequestId == null,
          child: Scaffold(
            backgroundColor: RescheduleRequestsStyle.cream,
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: NalaraPageLayout(
                    header: NalaraPageHeader(
                      title: 'Permintaan jadwal',
                      subtitle: widget.parent
                          ? 'Riwayat perubahan jadwal anak'
                          : 'Tinjau permintaan perubahan dari orang tua',
                      backEnabled: state.activeRequestId == null,
                      onBack: () => finishForm(
                        context,
                        widget.parent ? '/parent/schedule' : '/teacher/more',
                      ),
                      actions: [
                        IconButton(
                          key: const ValueKey('reschedule-requests-refresh'),
                          tooltip: 'Muat ulang permintaan',
                          onPressed: state.busy ? null : _cubit.refresh,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    body: _body(state),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _body(RescheduleRequestsState state) {
    final data = state.data;
    return RefreshIndicator(
      onRefresh: _cubit.refresh,
      child: CustomScrollView(
        key: PageStorageKey('reschedule-requests-$_prefix'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (state.loading && data != null)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          if (state.actionError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  state.actionError!,
                  style: RescheduleRequestsStyle.body.copyWith(
                    color: RescheduleRequestsStyle.red,
                  ),
                ),
              ),
            ),
          if (data == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: state.loadError != null
                  ? ErrorNotice(state.loadError!, retry: _cubit.retry)
                  : const Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (state.loadError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ErrorNotice(state.loadError!, retry: _cubit.retry),
                ),
              ),
            if (data.items.isEmpty && !state.loading && state.loadError == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyNotice(
                  'Belum ada permintaan perubahan jadwal.',
                  imagePath: 'assets/Empty/Jadwal kosong.png',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: data.items.length,
                  itemBuilder: (context, index) {
                    final request = data.items[index];
                    final enabled = state.canAct;
                    return Padding(
                      key: ValueKey(request.id),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RescheduleRequestCard(
                        request: request,
                        timezone: _timezone,
                        parent: widget.parent,
                        studentName: widget.studentNames[request.studentId],
                        studentGrade: widget.studentGrades[request.studentId],
                        busy: state.activeRequestId == request.id,
                        onApprove: enabled
                            ? () => _act(request, 'approved')
                            : null,
                        onReject: enabled
                            ? () => _act(request, 'rejected')
                            : null,
                        onPropose: enabled
                            ? () => _act(request, 'proposed')
                            : null,
                        onCancel: enabled
                            ? () => _act(request, 'cancel')
                            : null,
                        onAccept: enabled
                            ? () => _act(request, 'accept')
                            : null,
                        onDecline: enabled
                            ? () => _act(request, 'decline')
                            : null,
                      ),
                    );
                  },
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverToBoxAdapter(
                child: NalaraLoadMoreButton(
                  buttonKey: const ValueKey('reschedule-requests-load-more'),
                  hasMore: data.hasNext && state.loadError == null,
                  loading: state.busy,
                  onPressed: _cubit.loadMore,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
