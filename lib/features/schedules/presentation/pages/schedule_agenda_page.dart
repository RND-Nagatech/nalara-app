import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../utils/color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../utils/injector.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../domain/entities/schedule_period.dart';
import '../../domain/usecases/load_schedule_agenda.dart';
import '../bloc/schedule_agenda_cubit.dart';
import '../widgets/agenda_calendar.dart';
import '../widgets/agenda_header.dart';
import '../widgets/agenda_style.dart';
import '../widgets/agenda_tab_body.dart';

class ScheduleAgendaPage extends StatefulWidget {
  final DateTime? initialDate;
  final String initialPeriod, timezone;
  final bool attendance;
  final LoadScheduleAgenda? loadAgenda;
  final bool readOnly;
  final String routePrefix;
  final String? subtitle, emptyDescription;
  final List<Widget> headerActions;
  final List<Widget> Function(Future<void> Function())? headerActionsBuilder;
  const ScheduleAgendaPage({
    super.key,
    this.initialDate,
    this.initialPeriod = 'day',
    this.attendance = false,
    this.loadAgenda,
    this.readOnly = false,
    this.routePrefix = '/teacher',
    this.subtitle,
    this.emptyDescription,
    this.headerActions = const [],
    this.headerActionsBuilder,
    required this.timezone,
  });
  @override
  State<ScheduleAgendaPage> createState() => _ScheduleAgendaPageState();
}

class _ScheduleAgendaPageState extends State<ScheduleAgendaPage>
    with
        SingleTickerProviderStateMixin,
        TeachingCatalogRefresh<ScheduleAgendaPage> {
  late ScheduleAgendaCubit _cubit;
  late final TabController _tabs;
  String get _scope => widget.attendance ? 'attendance' : 'agenda';
  @override
  void onTeachingCatalogChanged() => _cubit.refresh();
  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      initialIndex: SchedulePeriod.parse(widget.initialPeriod).index,
      vsync: this,
    )..addListener(_tabChanged);
    _bindCubit();
  }

  void _bindCubit() {
    final loadAgenda = widget.loadAgenda;
    _cubit = loadAgenda == null
        ? getIt<ScheduleAgendaCubit>()
        : ScheduleAgendaCubit(loadAgenda);
    _initialize();
  }

  void _initialize() => _cubit.initialize(
    date: widget.initialDate,
    timezone: widget.timezone,
    period: SchedulePeriod.parse(widget.initialPeriod),
  );
  @override
  void didUpdateWidget(covariant ScheduleAgendaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadAgenda != widget.loadAgenda) {
      _cubit.close();
      _bindCubit();
      _tabs.animateTo(SchedulePeriod.parse(widget.initialPeriod).index);
    } else if (oldWidget.initialDate != widget.initialDate ||
        oldWidget.initialPeriod != widget.initialPeriod ||
        oldWidget.timezone != widget.timezone ||
        oldWidget.attendance != widget.attendance) {
      _initialize();
      _tabs.animateTo(SchedulePeriod.parse(widget.initialPeriod).index);
    }
  }

  void _tabChanged() {
    if (!_tabs.indexIsChanging && _tabs.index != _cubit.state.period.index) {
      _cubit.selectPeriod(SchedulePeriod.values[_tabs.index]);
    }
  }

  Future<void> _open(String route) async {
    final cubit = _cubit;
    await context.push(route);
    if (mounted && identical(cubit, _cubit)) await cubit.refresh();
  }

  Future<void> _add() async {
    if (!widget.readOnly) {
      await _open('${widget.routePrefix}/schedule/new');
    }
  }

  Future<void> _pick() async {
    final cubit = _cubit;
    final selected = cubit.state.date;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(selected.year, selected.month, selected.day),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date != null && mounted && identical(cubit, _cubit)) {
      await cubit.selectDate(date);
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
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
        ).colorScheme.copyWith(primary: AgendaStyle.green),
      ),
      child: BlocBuilder<ScheduleAgendaCubit, ScheduleAgendaState>(
        bloc: _cubit,
        builder: (context, state) {
          final height = math.max(
            48.0,
            MediaQuery.textScalerOf(context).scale(13) * 1.4 + 16,
          );
          final tabs = TabBar(
            key: ValueKey('$_scope-tabs'),
            controller: _tabs,
            onTap: (index) => _cubit.selectPeriod(SchedulePeriod.values[index]),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 1.8,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
            indicatorColor: AgendaStyle.green,
            dividerColor: NalaraColors.headerDivider,
            labelColor: AgendaStyle.green,
            unselectedLabelColor: AgendaStyle.muted,
            labelStyle: AgendaStyle.tab,
            unselectedLabelStyle: AgendaStyle.tab,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            tabs: [
              for (final period in SchedulePeriod.values)
                Tab(
                  key: ValueKey('$_scope-tab-${period.name}'),
                  height: height,
                  text: AgendaStyle.labels[period.index],
                ),
            ],
          );
          return Scaffold(
            backgroundColor: AgendaStyle.cream,
            floatingActionButton:
                !widget.readOnly &&
                    state.current?.data?.items.isNotEmpty == true
                ? FloatingActionButton.extended(
                    key: ValueKey('$_scope-add'),
                    heroTag: 'schedule-$_scope-add',
                    onPressed: _add,
                    backgroundColor: AgendaStyle.green,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: Text(widget.attendance ? 'Jadwal baru' : 'Tambah'),
                  )
                : null,
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: NalaraPageLayout(
                    showDivider: false,
                    header: AgendaHeader(
                      subtitle: widget.subtitle,
                      loading: state.current?.loading == true,
                      onRefresh: _cubit.refresh,
                      attendance: widget.attendance,
                      readOnly: widget.readOnly,
                      actions: [
                        ...widget.headerActions,
                        ...?widget.headerActionsBuilder?.call(_cubit.refresh),
                      ],
                      onBack: widget.attendance
                          ? () => finishForm(
                              context,
                              '${widget.routePrefix}/more',
                            )
                          : null,
                    ),
                    body: NestedScrollView(
                      headerSliverBuilder: (context, innerScrolled) => [
                        SliverOverlapAbsorber(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                context,
                              ),
                          sliver: SliverPersistentHeader(
                            pinned: true,
                            delegate: _AgendaTabs(tabs),
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
                          key: ValueKey('$_scope-tab-view'),
                          controller: _tabs,
                          children: [
                            for (final period in SchedulePeriod.values)
                              AgendaTabBody(
                                emptyDescription: widget.emptyDescription,
                                key: ValueKey('$_scope-body-${period.name}'),
                                attendance: widget.attendance,
                                readOnly: widget.readOnly,
                                date: state.date,
                                timezone: state.timezone,
                                period: period,
                                value: state.lists[period],
                                calendar: AgendaCalendar(
                                  date: state.date,
                                  period: period,
                                  onPrevious: _cubit.canMove(-1)
                                      ? () => _cubit.move(-1)
                                      : null,
                                  onNext: _cubit.canMove(1)
                                      ? () => _cubit.move(1)
                                      : null,
                                  onPick: _pick,
                                  onDay: (date) {
                                    if (period == SchedulePeriod.month) {
                                      _cubit.showDay(date);
                                      _tabs.animateTo(SchedulePeriod.day.index);
                                    } else {
                                      _cubit.selectDate(date);
                                    }
                                  },
                                ),
                                onRefresh: _cubit.refresh,
                                onRetry: () => _cubit.retry(period),
                                onAdd: _add,
                                onOpen: (lesson) => _open(
                                  '${widget.routePrefix}/sessions/${Uri.encodeComponent(lesson.id)}',
                                ),
                                onLoadMore: () => _cubit.loadMore(period),
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

class _AgendaTabs extends SliverPersistentHeaderDelegate {
  final TabBar tabs;
  _AgendaTabs(this.tabs);
  @override
  double get minExtent => tabs.preferredSize.height;
  @override
  double get maxExtent => minExtent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(color: AgendaStyle.cream, child: tabs);
  @override
  bool shouldRebuild(covariant _AgendaTabs oldDelegate) =>
      oldDelegate.tabs != tabs;
}
