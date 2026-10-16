import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/teacher_home.dart';
import '../bloc/dashboard_cubit.dart';
import '../widgets/home_header.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_style.dart';
import '../widgets/home_dashboard_view.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver, TeachingCatalogRefresh<DashboardPage> {
  late final DashboardCubit _cubit;
  GoRouter? _router;
  bool _homeVisible = true;
  @override
  void onTeachingCatalogChanged() => _cubit.load();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = getIt<DashboardCubit>()..load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (identical(router, _router)) return;
    _router?.routerDelegate.removeListener(_routeChanged);
    _router = router;
    _homeVisible = router == null || router.state.uri.path == '/teacher/home';
    router?.routerDelegate.addListener(_routeChanged);
  }

  void _routeChanged() {
    final visible = _router?.state.uri.path == '/teacher/home';
    final returning = visible && !_homeVisible;
    _homeVisible = visible;
    if (returning && mounted) _cubit.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _homeVisible) _cubit.load();
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DashboardCubit, LoadState<TeacherHome>>(
        bloc: _cubit,
        builder: (context, state) {
          final home = state.value;
          final data = home?.overview;
          void schedule() {
            if (data != null) context.go(HomeStyle.scheduleRoute(data));
          }

          return HomeDashboardView(
            header: HomeHeader(
              data: data,
              onProfile: () => context.push('/teacher/profile'),
              onNotifications: () => context.push('/teacher/notifications'),
            ),
            hero: data == null
                ? null
                : HomeHero(
                    data: data,
                    onStudents: () => context.go('/teacher/students'),
                    onSchedule: schedule,
                    onReports: () => context.push('/teacher/reports'),
                  ),
            sessions: home?.previewSessions,
            timezone: data?.teacher.timezone ?? '',
            loading: state.status == LoadStatus.loading,
            error: state.error,
            onRefresh: _cubit.load,
            onSchedule: schedule,
            onSession: (lesson) =>
                context.push('/teacher/sessions/${lesson.id}'),
            onCreate: () => context.push('/teacher/schedule/new'),
          );
        },
      );
}
