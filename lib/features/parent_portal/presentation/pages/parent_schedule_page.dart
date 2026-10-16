import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../../schedules/domain/usecases/load_schedule_agenda.dart';
import '../../../schedules/presentation/pages/schedule_agenda_page.dart';
import '../../../schedules/presentation/widgets/agenda_header.dart';
import '../../../schedules/presentation/widgets/agenda_style.dart';
import '../../domain/repositories/parent_portal_repository.dart';

/// The teacher calendar and attendance presentation with parent-scoped reads.
class ParentSharedSchedulePage extends StatefulWidget {
  final bool attendance;
  final DateTime? initialDate;
  final String? initialPeriod;

  /// Defaults to the parent dashboard's authoritative timezone when omitted.
  final String? timezone;

  const ParentSharedSchedulePage({
    super.key,
    this.attendance = false,
    this.initialDate,
    this.initialPeriod,
    this.timezone,
  });

  @override
  State<ParentSharedSchedulePage> createState() =>
      _ParentSharedSchedulePageState();
}

class _ParentSharedSchedulePageState extends State<ParentSharedSchedulePage> {
  late final ParentPortalRepository _repository;
  late final LoadScheduleAgenda _loadAgenda;
  late LoadCubit<String> _timezone;

  @override
  void initState() {
    super.initState();
    _repository = getIt<ParentPortalRepository>();
    _loadAgenda = LoadScheduleAgenda.fromSessions(
      sessions: _repository.sessions,
    );
    _bindTimezone();
  }

  void _bindTimezone() {
    final timezone = widget.timezone;
    _timezone = LoadCubit<String>(
      () async => timezone ?? (await _repository.dashboard()).timezone,
    )..load();
  }

  @override
  void didUpdateWidget(covariant ParentSharedSchedulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timezone != widget.timezone) {
      _timezone.close();
      _bindTimezone();
    }
  }

  @override
  void dispose() {
    _timezone.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LoadCubit<String>, LoadState<String>>(
        bloc: _timezone,
        builder: (context, state) {
          if (state.value != null) {
            return ScheduleAgendaPage(
              initialDate: widget.initialDate,
              initialPeriod:
                  widget.initialPeriod ?? (widget.attendance ? 'week' : 'day'),
              timezone: state.value!,
              attendance: widget.attendance,
              loadAgenda: _loadAgenda,
              readOnly: true,
              routePrefix: '/parent',
              headerActionsBuilder: (refresh) => widget.attendance
                  ? const []
                  : [
                      IconButton(
                        key: const ValueKey('parent-reschedule-requests'),
                        tooltip: 'Permintaan perubahan jadwal',
                        onPressed: () async {
                          await context.push('/parent/reschedule-requests');
                          if (mounted) await refresh();
                        },
                        icon: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AgendaStyle.green,
                        ),
                      ),
                    ],
            );
          }
          return Scaffold(
            backgroundColor: AgendaStyle.cream,
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: NalaraPageLayout(
                    header: AgendaHeader(
                      loading: state.status == LoadStatus.loading,
                      onRefresh: _timezone.load,
                      attendance: widget.attendance,
                      readOnly: true,
                      onBack: widget.attendance
                          ? () => finishForm(context, '/parent/more')
                          : null,
                    ),
                    body: state.status == LoadStatus.error
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: ErrorNotice(
                              state.error!,
                              retry: _timezone.load,
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AgendaStyle.green,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
