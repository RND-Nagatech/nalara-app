import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../dashboard/presentation/widgets/home_dashboard_view.dart';
import '../../../dashboard/presentation/widgets/home_role_widgets.dart';
import '../../../dashboard/presentation/widgets/home_style.dart';
import '../../../learning_goals/presentation/widgets/learning_plan_card.dart';
import '../../../learning_goals/domain/usecases/update_progress.dart';
import '../../../learning_goals/presentation/widgets/learning_plans_empty_state.dart';
import '../../../lesson_reports/presentation/widgets/report_list_card.dart';
import '../../../lesson_reports/presentation/widgets/reports_empty_state.dart';
import '../../domain/entities/student_portal.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../bloc/student_dashboard_cubit.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});
  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage>
    with WidgetsBindingObserver {
  late final _cubit = StudentDashboardCubit(getIt<StudentPortalRepository>())
    ..load();
  GoRouter? _router;
  bool _visible = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (identical(router, _router)) return;
    _router?.routerDelegate.removeListener(_routeChanged);
    _router = router;
    _visible = router == null || router.state.uri.path == '/student/home';
    _router?.routerDelegate.addListener(_routeChanged);
  }

  void _routeChanged() {
    final visible = _router?.state.uri.path == '/student/home';
    final returning = visible && !_visible;
    _visible = visible;
    if (returning && mounted) _cubit.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _visible) _cubit.load();
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  String _schedule(StudentDashboard data) => Uri(
    path: '/student/schedule',
    queryParameters: {
      'date': DateFormat(
        'yyyy-MM-dd',
      ).format(DateTimeUtils.local(data.generatedAt, data.timezone)),
      'period': 'day',
    },
  ).toString();
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<StudentDashboardCubit, LoadState<StudentDashboard>>(
    bloc: _cubit,
    builder: (context, state) {
      final data = state.value;
      void schedule() {
        if (data != null) context.go(_schedule(data));
      }

      return HomeDashboardView(
        header: HomeRoleHeader(
          name: data?.student.name ?? '',
          date: data == null
              ? 'Beranda Siswa'
              : DateFormat(
                  'EEEE, d MMMM yyyy',
                  'id_ID',
                ).format(DateTimeUtils.local(data.generatedAt, data.timezone)),
          unreadNotifications: data?.unreadNotifications ?? 0,
          onProfile: () => context.push('/student/profile'),
          onNotifications: () => context.push('/student/notifications'),
          profileTooltip: 'Profil saya',
        ),
        hero: data == null
            ? null
            : HomeRoleHero(
                greeting: 'Selamat belajar,',
                name: data.student.name.toUpperCase(),
                supporting: data.student.grade.isEmpty
                    ? 'Semangat belajar hari ini!'
                    : data.student.grade,
                metrics: [
                  HomeRoleMetric(
                    value: '${data.sessionsToday}',
                    label: 'Les hari ini',
                    iconAsset: HomeStyle.todayLessonsIcon,
                    tint: const Color(0xFFF6F8F0),
                    iconTint: const Color(0xFFE9EFE4),
                    onTap: schedule,
                  ),
                  HomeRoleMetric(
                    value: data.progress == null ? '—' : '${data.progress}%',
                    label: 'Progress target',
                    iconAsset: 'assets/Icon/Icon detail target.png',
                    tint: const Color(0xFFF7F8F2),
                    iconTint: const Color(0xFFE9EFE4),
                    onTap: () => context.go('/student/targets'),
                  ),
                  HomeRoleMetric(
                    value: '${data.pendingHomework}',
                    label: 'Tugas baru',
                    iconAsset: HomeStyle.pendingReportsIcon,
                    tint: const Color(0xFFFDECE9),
                    iconTint: const Color(0xFFF9E0DA),
                    onTap: () => context.push('/student/materials'),
                  ),
                ],
              ),
        sessions: data?.todaySessions,
        timezone: data?.timezone ?? '',
        loading: state.status == LoadStatus.loading,
        error: state.error,
        onRefresh: _cubit.load,
        onSchedule: schedule,
        scheduleTitle: 'Jadwal les hari ini',
        onSession: (lesson) => context.push('/student/sessions/${lesson.id}'),
        emptyDescription: 'Jadwal yang dibagikan Guru akan muncul di sini.',
        extraSlivers: data == null
            ? const []
            : [
                SliverToBoxAdapter(
                  child: HomeSectionHeading(
                    title: 'Progress target belajar',
                    onViewAll: () => context.go('/student/targets'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: data.plans.isEmpty
                      ? SliverToBoxAdapter(
                          child: LearningPlansEmptyState(
                            onAdd: () {},
                            showAction: false,
                            description:
                                'Rencana dan target yang dibuat Guru akan muncul di sini.',
                          ),
                        )
                      : SliverList.builder(
                          itemCount: data.plans.length,
                          itemBuilder: (context, index) {
                            final plan = data.plans[index];
                            return LearningPlanCard(
                              plan: plan,
                              progressLabel: PlanProgressLabel()(plan),
                              onTap: () =>
                                  context.push('/student/plans/${plan.id}'),
                            );
                          },
                        ),
                ),
                SliverToBoxAdapter(
                  child: HomeSectionHeading(
                    title: 'Laporan terbaru',
                    onViewAll: () => context.go('/student/reports'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: data.recentReports.isEmpty
                      ? SliverToBoxAdapter(
                          child: ReportsEmptyState(
                            status: 'published',
                            onAdd: () {},
                            showAction: false,
                          ),
                        )
                      : SliverList.builder(
                          itemCount: data.recentReports.length,
                          itemBuilder: (context, index) {
                            final report = data.recentReports[index];
                            return ReportListCard(
                              report: report,
                              onTap: () =>
                                  context.push('/student/reports/${report.id}'),
                            );
                          },
                        ),
                ),
              ],
      );
    },
  );
}
