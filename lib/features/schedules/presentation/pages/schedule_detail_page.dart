import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/schedules_repository.dart';
import '../widgets/schedule_series_header.dart';
import '../widgets/schedule_series_summary.dart';
import '../widgets/session_detail_style.dart';

class ScheduleDetailPage extends StatefulWidget {
  final String id;
  const ScheduleDetailPage({super.key, required this.id});
  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late LoadCubit<Schedule> _loader;
  late SubmitCubit _submit;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    final id = widget.id;
    _loader = LoadCubit<Schedule>(
      () => getIt<SchedulesRepository>().schedule(id),
    )..load();
    _submit = SubmitCubit();
    _confirming = false;
  }

  @override
  void didUpdateWidget(covariant ScheduleDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
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

  bool get _visible {
    final router = GoRouter.maybeOf(context);
    return (ModalRoute.of(context)?.isCurrent ?? true) &&
        (router == null ||
            router.state.uri.path ==
                '/teacher/schedule/${Uri.encodeComponent(widget.id)}');
  }

  Future<void> _refresh() async {
    if (!_submit.state.busy && !_confirming) await _loader.load();
  }

  Future<void> _openSessions() async {
    if (_submit.state.busy || _confirming) return;
    final loader = _loader;
    await context.push(
      '/teacher/schedule/${Uri.encodeComponent(widget.id)}/sessions',
    );
    if (mounted && identical(loader, _loader)) await loader.load();
  }

  Future<void> _cancel() async {
    final loader = _loader, submit = _submit;
    if (submit.state.busy ||
        _confirming ||
        loader.state.status != LoadStatus.success ||
        loader.state.value?.status == 'cancelled') {
      return;
    }
    final id = widget.id;
    setState(() => _confirming = true);
    final confirmed = await confirmAction(
      context,
      'Batalkan seluruh pertemuan terjadwal dalam seri ini? Sesi selesai tetap tersimpan.',
    );
    if (!mounted || !identical(loader, _loader)) return;
    setState(() => _confirming = false);
    if (!confirmed || !_visible) return;
    final ok = await submit.run(
      () => getIt<SchedulesRepository>().cancelSeries(id),
    );
    if (!mounted || !identical(loader, _loader)) return;
    if (ok) {
      if (_visible) successMessage(context, 'Seri dibatalkan');
      await loader.load();
    }
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
              constraints: const BoxConstraints(maxWidth: 680),
              child: BlocBuilder<SubmitCubit, SubmitState>(
                bloc: _submit,
                builder: (context, submit) =>
                    BlocBuilder<LoadCubit<Schedule>, LoadState<Schedule>>(
                      bloc: _loader,
                      builder: (context, state) => RefreshIndicator(
                        color: SessionDetailStyle.green,
                        onRefresh: _refresh,
                        child: NalaraPageLayout(
                          header: ScheduleSeriesHeader(
                            onBack: submit.busy || _confirming
                                ? null
                                : () =>
                                      finishForm(context, '/teacher/schedule'),
                          ),
                          body: ListView(
                            key: PageStorageKey('series-detail-${widget.id}'),
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            children: [
                              const ScheduleSeriesIntro(),
                              if (state.status == LoadStatus.error)
                                _error(state.error!)
                              else if (state.value == null)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else ...[
                                if (state.status == LoadStatus.loading)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: LinearProgressIndicator(),
                                  ),
                                ScheduleSeriesSummary(
                                  key: const ValueKey('series-summary'),
                                  schedule: state.value!,
                                ),
                                _actions(state, submit),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _error(String message) => SessionSectionCard(
    key: const ValueKey('series-load-error'),
    title: 'Seri jadwal belum dapat dimuat',
    children: [
      Text(message, style: SessionDetailStyle.body),
      const SizedBox(height: 14),
      FilledButton(
        key: const ValueKey('series-retry'),
        onPressed: _refresh,
        child: const Text('Coba lagi'),
      ),
    ],
  );

  Widget _actions(LoadState<Schedule> state, SubmitState submit) {
    final enabled =
        state.status == LoadStatus.success && !submit.busy && !_confirming;
    final cancelled = state.value!.status == 'cancelled';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionActionTile(
          key: const ValueKey('series-sessions'),
          label: 'Lihat seluruh pertemuan',
          description: 'Lihat dan kelola semua sesi dalam seri ini.',
          icon: Icons.format_list_bulleted_rounded,
          onPressed: enabled ? _openSessions : null,
        ),
        const SizedBox(height: 20),
        if (submit.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                submit.error!,
                key: const ValueKey('series-submit-error'),
                style: SessionDetailStyle.body.copyWith(
                  color: SessionDetailStyle.red,
                ),
              ),
            ),
          ),
        if (!cancelled) ...[
          FilledButton(
            key: const ValueKey('series-cancel'),
            onPressed: enabled ? _cancel : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (submit.busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'Batalkan semua sesi tersisa',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ScheduleSeriesWarning(
          key: const ValueKey('series-warning'),
          cancelled: cancelled,
        ),
      ],
    );
  }
}
