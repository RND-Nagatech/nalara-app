import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../dashboard/presentation/widgets/home_empty_schedule.dart';
import '../../../dashboard/presentation/widgets/home_lesson_card.dart';
import '../../../dashboard/presentation/widgets/home_role_widgets.dart';
import '../../../dashboard/presentation/widgets/home_style.dart';
import '../../../learning_goals/presentation/widgets/target_card.dart';
import '../../../learning_goals/presentation/widgets/learning_plans_empty_state.dart';
import '../../../lesson_reports/presentation/widgets/report_list_card.dart';
import '../../../lesson_reports/presentation/widgets/reports_empty_state.dart';
import '../../domain/entities/parent_portal.dart';
import '../../domain/repositories/parent_portal_repository.dart';
import '../bloc/parent_dashboard_cubit.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});
  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage>
    with WidgetsBindingObserver {
  late final ParentDashboardCubit _cubit;
  GoRouter? _router;
  bool _visible = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = ParentDashboardCubit(getIt<ParentPortalRepository>())..refresh();
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _visible) _cubit.refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (identical(router, _router)) return;
    _router?.routerDelegate.removeListener(_routeChanged);
    _router = router;
    _visible = router == null || router.state.uri.path == '/parent/home';
    _router?.routerDelegate.addListener(_routeChanged);
  }

  void _routeChanged() {
    final visible = _router?.state.uri.path == '/parent/home';
    final returning = visible && !_visible;
    _visible = visible;
    if (returning && mounted) _cubit.refresh();
  }

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted && _router == null) await _cubit.refresh();
  }

  String _schedule(ParentDashboard data) => Uri(
    path: '/parent/schedule',
    queryParameters: {
      'date': DateFormat(
        'yyyy-MM-dd',
      ).format(DateTimeUtils.local(data.generatedAt, data.timezone)),
      'period': 'day',
      'timezone': data.timezone,
    },
  ).toString();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HomeStyle.cream,
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: BlocBuilder<ParentDashboardCubit, ParentDashboardState>(
            bloc: _cubit,
            builder: (context, state) {
              final data = state.data;
              final header = HomeRoleHeader(
                name:
                    data?.parentName ??
                    getIt<AuthCubit>().state.accessProfile?.name ??
                    '',
                date: data == null
                    ? 'Beranda Orang Tua'
                    : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(
                        DateTimeUtils.local(data.generatedAt, data.timezone),
                      ),
                unreadNotifications: data?.unreadNotifications ?? 0,
                onProfile: () => _open('/parent/profile'),
                onNotifications: () => _open('/parent/notifications'),
                profileTooltip: 'Profil orang tua',
              );
              return NalaraPageLayout(
                header: header,
                bottomSpacing: 0,
                body: data == null
                    ? Column(
                        children: [
                          if (state.children.length > 1) _switcher(state),
                          Expanded(
                            child: state.error == null
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ErrorNotice(
                                    state.error!,
                                    retry: _cubit.refresh,
                                  ),
                          ),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: _cubit.refresh,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(child: _hero(data)),
                            if (state.loading)
                              const SliverToBoxAdapter(
                                child: LinearProgressIndicator(),
                              ),
                            if (state.error != null)
                              SliverToBoxAdapter(
                                child: ErrorNotice(
                                  state.error!,
                                  retry: _cubit.refresh,
                                ),
                              ),
                            if (state.children.length > 1)
                              SliverToBoxAdapter(child: _switcher(state)),
                            _section(
                              'Jadwal les anak hari ini',
                              () => context.go(_schedule(data)),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              sliver: data.todaySessions.isEmpty
                                  ? SliverToBoxAdapter(
                                      child: HomeEmptySchedule(
                                        onCreate: () {},
                                        showAction: false,
                                        description:
                                            'Jadwal les anak Anda akan muncul di sini.',
                                      ),
                                    )
                                  : SliverList.builder(
                                      itemCount: data.todaySessions.length,
                                      itemBuilder: (context, index) =>
                                          HomeLessonCard(
                                            lesson: data.todaySessions[index],
                                            timezone: data.timezone,
                                            accent: HomeStyle.green,
                                            onTap: () => _open(
                                              '/parent/sessions/${data.todaySessions[index].id}',
                                            ),
                                          ),
                                    ),
                            ),
                            _section(
                              'Laporan terbaru',
                              () => _open('/parent/reports'),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              sliver: data.latestReports.isEmpty
                                  ? SliverToBoxAdapter(
                                      child: ReportsEmptyState(
                                        status: 'published',
                                        onAdd: () {},
                                        showAction: false,
                                      ),
                                    )
                                  : SliverList.builder(
                                      itemCount: data.latestReports.length,
                                      itemBuilder: (context, index) =>
                                          ReportListCard(
                                            report: data.latestReports[index],
                                            onTap: () => _open(
                                              '/parent/reports/${data.latestReports[index].id}',
                                            ),
                                          ),
                                    ),
                            ),
                            _section(
                              'Target yang perlu perhatian',
                              () => context.go('/parent/targets'),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              sliver: data.attentionTargetItems.isEmpty
                                  ? SliverToBoxAdapter(
                                      child: LearningPlansEmptyState(
                                        onAdd: () {},
                                        showAction: false,
                                        title:
                                            'Belum ada target yang perlu perhatian.',
                                        description:
                                            'Target dengan progres di bawah 50% akan muncul di sini.',
                                      ),
                                    )
                                  : SliverList.builder(
                                      itemCount:
                                          data.attentionTargetItems.length,
                                      itemBuilder: (context, index) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: TargetCard(
                                          target:
                                              data.attentionTargetItems[index],
                                          onTap: () => _open(
                                            '/parent/targets/${data.attentionTargetItems[index].id}',
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 34),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _switcher(ParentDashboardState state) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
    child: NalaraDropdown<String>(
      value: state.studentId ?? '',
      decoration: const InputDecoration(labelText: 'Tampilkan anak'),
      options: [
        const NalaraDropdownOption(value: '', label: 'Semua anak'),
        ...state.children.map(
          (child) => NalaraDropdownOption(
            value: child.id,
            label: child.name,
            searchText: child.grade,
          ),
        ),
      ],
      onChanged: (id) => _cubit.selectChild(id == '' ? null : id),
    ),
  );
  Widget _hero(ParentDashboard data) => HomeRoleHero(
    greeting: 'Selamat datang,',
    name: '${data.parentName.toUpperCase()} 👋',
    supporting: 'Pantau perjalanan belajar anak Anda.',
    metrics: [
      HomeRoleMetric(
        value: '${data.childrenCount}',
        label: 'Anak terhubung',
        iconAsset: HomeStyle.activeStudentsIcon,
        tint: const Color(0xFFF6F8F0),
        iconTint: const Color(0xFFE9EFE4),
        onTap: () => context.go('/parent/students'),
      ),
      HomeRoleMetric(
        value: '${data.sessionsToday}',
        label: 'Les hari ini',
        iconAsset: HomeStyle.todayLessonsIcon,
        tint: const Color(0xFFF7F8F2),
        iconTint: const Color(0xFFE9EFE4),
        onTap: () => context.go(_schedule(data)),
      ),
      HomeRoleMetric(
        value: data.weeklyProgress == null ? '—' : '${data.weeklyProgress}%',
        label: 'Progress minggu ini',
        iconAsset: 'assets/Icon/Icon detail target.png',
        tint: const Color(0xFFF6F8F0),
        iconTint: const Color(0xFFE9EFE4),
        onTap: () => context.go('/parent/targets'),
      ),
    ],
  );
  Widget _section(String title, VoidCallback onAll) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(22, 22, 18, 12),
    sliver: SliverToBoxAdapter(
      child: Row(
        children: [
          Expanded(child: Text(title, style: HomeStyle.heading)),
          TextButton(
            onPressed: onAll,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat semua',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
