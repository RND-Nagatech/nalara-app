import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../../schedules/domain/usecases/load_schedule_agenda.dart';
import '../../../schedules/presentation/pages/schedule_agenda_page.dart';
import '../../../schedules/presentation/pages/session_detail_page.dart';
import '../../../schedules/presentation/widgets/agenda_header.dart';
import '../../../schedules/presentation/widgets/agenda_style.dart';
import '../../domain/repositories/student_portal_repository.dart';

/// The teacher calendar, including date arithmetic, swipe tabs and pagination.
class StudentSchedulePage extends StatefulWidget {
  final bool attendance;
  final DateTime? initialDate;
  final String initialPeriod;
  const StudentSchedulePage({
    super.key,
    this.attendance = false,
    this.initialDate,
    this.initialPeriod = 'day',
  });
  @override
  State<StudentSchedulePage> createState() => _StudentSchedulePageState();
}

class _StudentSchedulePageState extends State<StudentSchedulePage> {
  late final _repository = getIt<StudentPortalRepository>();
  late final _loadAgenda = LoadScheduleAgenda.fromSessions(
    sessions: _repository.sessions,
  );
  late final _timezone = LoadCubit<String>(
    () async => (await _repository.dashboard()).timezone,
  )..load();
  String get _subtitle => widget.attendance
      ? 'Lihat kehadiran Anda di setiap sesi belajar.'
      : 'Lihat jadwal belajar Anda';
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
              initialPeriod: widget.initialPeriod,
              timezone: state.value!,
              attendance: widget.attendance,
              loadAgenda: _loadAgenda,
              readOnly: true,
              routePrefix: '/student',
              subtitle: _subtitle,
              emptyDescription: widget.attendance
                  ? 'Kehadiran Anda pada periode ini akan muncul di sini.'
                  : 'Jadwal yang dibagikan Guru akan muncul di sini.',
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
                      subtitle: _subtitle,
                      onBack: widget.attendance
                          ? () => finishForm(context, '/student/more')
                          : null,
                    ),
                    body: state.error != null
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: ErrorNotice(
                              state.error!,
                              retry: _timezone.load,
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class StudentSessionDetailPage extends StatelessWidget {
  final String id;
  const StudentSessionDetailPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) => SessionDetailPage(
    id: id,
    loadOverview: getIt<StudentPortalRepository>().sessionOverview,
    readOnly: true,
    routePrefix: '/student',
    studentRoute: '/student/profile',
    allowSeriesNavigation: false,
  );
}
