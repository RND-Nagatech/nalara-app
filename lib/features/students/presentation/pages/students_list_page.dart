import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../utils/color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/student_filter.dart';
import '../../domain/usecases/load_students.dart';
import '../bloc/students_cubit.dart';
import '../widgets/students_header.dart';
import '../widgets/students_style.dart';
import '../widgets/students_tab_body.dart';

class StudentsPage extends StatefulWidget {
  final LoadStudents? loader;
  final bool readOnly;
  final String routePrefix;
  const StudentsPage({
    super.key,
    this.loader,
    this.readOnly = false,
    this.routePrefix = '/teacher',
  }) : assert(!readOnly || loader != null);
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        TeachingCatalogRefresh<StudentsPage> {
  final _search = TextEditingController();
  late final StudentsCubit _cubit;
  late final TabController _tabs;
  GoRouter? _router;
  bool _visible = true;

  @override
  void onTeachingCatalogChanged() => _cubit.refresh();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: StudentFilter.values.length, vsync: this)
      ..addListener(_tabChanged);
    _cubit =
        (widget.loader == null
              ? getIt<StudentsCubit>()
              : StudentsCubit(widget.loader!))
          ..select(StudentFilter.active);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (identical(router, _router)) return;
    _router?.routerDelegate.removeListener(_routeChanged);
    _router = router;
    _visible =
        router == null ||
        router.state.uri.path == '${widget.routePrefix}/students';
    router?.routerDelegate.addListener(_routeChanged);
  }

  void _routeChanged() {
    final visible = _router?.state.uri.path == '${widget.routePrefix}/students';
    final returning = visible && !_visible;
    _visible = visible;
    if (mounted && returning) _cubit.refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _visible) _cubit.refresh();
  }

  void _tabChanged() {
    if (!_tabs.indexIsChanging && _tabs.index != _cubit.state.selected.index) {
      _cubit.select(StudentFilter.values[_tabs.index]);
    }
  }

  void _open(String route) {
    FocusScope.of(context).unfocus();
    context.push(route);
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
    _search.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'NalaraInter'),
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: StudentsStyle.green),
      ),
      child: BlocBuilder<StudentsCubit, StudentsState>(
        bloc: _cubit,
        builder: (context, state) {
          final tabHeight = math.max(
            48.0,
            MediaQuery.textScalerOf(context).scale(13) * 1.4 + 16,
          );
          final tabBar = TabBar(
            key: const ValueKey('students-tabs'),
            controller: _tabs,
            onTap: (index) => _cubit.select(StudentFilter.values[index]),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 1.8,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
            indicatorColor: StudentsStyle.green,
            dividerColor: NalaraColors.headerDivider,
            labelColor: StudentsStyle.green,
            unselectedLabelColor: StudentsStyle.muted,
            labelStyle: StudentsStyle.tab,
            unselectedLabelStyle: StudentsStyle.tab,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            tabs: [
              Tab(
                key: const ValueKey('students-tab-active'),
                height: tabHeight,
                text: 'Aktif',
              ),
              Tab(
                key: const ValueKey('students-tab-archived'),
                height: tabHeight,
                text: 'Arsip',
              ),
              Tab(
                key: const ValueKey('students-tab-all'),
                height: tabHeight,
                text: 'Semua',
              ),
            ],
          );
          return Scaffold(
            backgroundColor: StudentsStyle.cream,
            floatingActionButton:
                !widget.readOnly && state.current.data?.items.isNotEmpty == true
                ? FloatingActionButton.extended(
                    key: const ValueKey('students-add'),
                    heroTag: 'students-add',
                    backgroundColor: StudentsStyle.green,
                    foregroundColor: Colors.white,
                    onPressed: () => _open('/teacher/students/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  )
                : null,
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: NalaraPageLayout(
                    showDivider: false,
                    header: StudentsHeader(
                      readOnly: widget.readOnly,
                      search: _search,
                      loading: state.current.loading,
                      onRefresh: _cubit.refresh,
                      onChanged: _cubit.search,
                      onClear: () {
                        _search.clear();
                        _cubit.search('', immediate: true);
                      },
                      onSubmitted: (value) {
                        FocusScope.of(context).unfocus();
                        _cubit.search(value, immediate: true);
                      },
                    ),
                    body: NestedScrollView(
                      key: const ValueKey('students-scroll'),
                      headerSliverBuilder: (context, innerScrolled) => [
                        SliverOverlapAbsorber(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                context,
                              ),
                          sliver: SliverPersistentHeader(
                            pinned: true,
                            delegate: _StudentsTabs(tabBar),
                          ),
                        ),
                      ],
                      body: ScrollConfiguration(
                        behavior: const MaterialScrollBehavior().copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                            PointerDeviceKind.invertedStylus,
                          },
                        ),
                        child: TabBarView(
                          key: const ValueKey('students-tab-view'),
                          controller: _tabs,
                          children: [
                            for (final filter in StudentFilter.values)
                              StudentsTabBody(
                                key: ValueKey('students-body-${filter.name}'),
                                filter: filter,
                                value: state.forFilter(filter),
                                onRefresh: _cubit.refresh,
                                onRetry: () => _cubit.retry(filter),
                                onAdd: () => _open('/teacher/students/new'),
                                onOpen: (student) => _open(
                                  '${widget.routePrefix}/students/${Uri.encodeComponent(student.id)}',
                                ),
                                readOnly: widget.readOnly,
                                onLoadMore: () =>
                                    _cubit.loadMore(filter: filter),
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
        },
      ),
    ),
  );
}

class _StudentsTabs extends SliverPersistentHeaderDelegate {
  final TabBar tabs;
  _StudentsTabs(this.tabs);
  @override
  double get minExtent => tabs.preferredSize.height;
  @override
  double get maxExtent => minExtent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(color: StudentsStyle.cream, child: tabs);
  @override
  bool shouldRebuild(covariant _StudentsTabs oldDelegate) =>
      oldDelegate.tabs != tabs;
}
