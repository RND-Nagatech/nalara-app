import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../shared/widgets/teacher_bottom_navigation.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/plan_overview.dart';
import '../../domain/usecases/load_plan_overview.dart';
import '../widgets/plan_detail_style.dart';
import '../widgets/plan_overview_cards.dart';
import '../widgets/target_card.dart';

class PlanDetailPage extends StatefulWidget {
  final String id;
  final Future<PlanOverview> Function(String id)? loadPlan;
  final bool readOnly;
  final String routePrefix;
  final Widget? bottomNavigationBar;
  final String? studentRoute;
  const PlanDetailPage({
    super.key,
    required this.id,
    this.loadPlan,
    this.readOnly = false,
    this.routePrefix = '/teacher',
    this.bottomNavigationBar,
    this.studentRoute,
  }) : assert(!readOnly || loadPlan != null);
  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage>
    with TeachingCatalogRefresh<PlanDetailPage> {
  late LoadCubit<PlanOverview> _loader;
  @override
  void onTeachingCatalogChanged() => _loader.load();
  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    final id = widget.id;
    final loadPlan = widget.loadPlan;
    _loader = LoadCubit(
      () => loadPlan != null ? loadPlan(id) : getIt<LoadPlanOverview>()(id),
    )..load();
  }

  @override
  void didUpdateWidget(covariant PlanDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.loadPlan != widget.loadPlan) {
      _loader.close();
      _bind();
    }
  }

  @override
  void dispose() {
    _loader.close();
    super.dispose();
  }

  Future<void> _open(String route) async {
    final loader = _loader;
    await context.push(route);
    if (mounted && identical(loader, _loader)) await loader.load();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: PlanDetailStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: PlanDetailStyle.cream,
        bottomNavigationBar:
            widget.bottomNavigationBar ??
            (widget.readOnly
                ? null
                : TeacherBottomNavigation(
                    selectedIndex: 3,
                    onDestinationSelected: (index) =>
                        context.go(teacherNavigationLocations[index]),
                  )),
        body: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  NalaraHeader(child: _header()),
                  Expanded(
                    child:
                        BlocBuilder<
                          LoadCubit<PlanOverview>,
                          LoadState<PlanOverview>
                        >(
                          bloc: _loader,
                          builder: (context, state) => RefreshIndicator(
                            color: PlanDetailStyle.green,
                            onRefresh: _loader.load,
                            child: state.value == null
                                ? ListView(
                                    key: ValueKey(
                                      'plan-detail-scroll-${widget.id}',
                                    ),
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(20),
                                    children: [
                                      if (state.error != null)
                                        ErrorNotice(
                                          state.error!,
                                          retry: _loader.load,
                                        )
                                      else
                                        const Padding(
                                          padding: EdgeInsets.all(60),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                    ],
                                  )
                                : _body(
                                    state.value!,
                                    state.status == LoadStatus.loading,
                                    state.error,
                                  ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 20, 18),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('plan-detail-back'),
          tooltip: 'Kembali',
          onPressed: () => finishForm(context, '${widget.routePrefix}/targets'),
          style: IconButton.styleFrom(
            foregroundColor: PlanDetailStyle.green,
            minimumSize: const Size(42, 42),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 25),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Rencana belajar',
            style: PlanDetailStyle.title.copyWith(fontSize: 18),
          ),
        ),
      ],
    ),
  );

  Widget _body(
    PlanOverview data,
    bool loading,
    String? error,
  ) => CustomScrollView(
    key: ValueKey('plan-detail-scroll-${widget.id}'),
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
        sliver: SliverList.list(
          children: [
            if (loading) const LinearProgressIndicator(),
            if (error != null) ErrorNotice(error, retry: _loader.load),
            Text(
              data.plan.title,
              key: const ValueKey('plan-detail-title'),
              style: PlanDetailStyle.title.copyWith(
                fontSize: 24,
                color: PlanDetailStyle.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ringkasan rencana belajar dan perkembangan target siswa.',
              style: PlanDetailStyle.body,
            ),
            const SizedBox(height: 24),
            PlanInformationCard(
              key: const ValueKey('plan-info-card'),
              data: data,
              onStudent: () => _open(
                widget.studentRoute ??
                    '${widget.routePrefix}/students/${Uri.encodeComponent(data.student.id)}',
              ),
            ),
            const SizedBox(height: 20),
            PlanAggregateCard(
              key: const ValueKey('plan-overall-card'),
              plan: data.plan,
            ),
            const SizedBox(height: 25),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  'Daftar target',
                  style: PlanDetailStyle.title.copyWith(
                    fontSize: 20,
                    color: PlanDetailStyle.ink,
                  ),
                ),
                Container(
                  key: const ValueKey('plan-target-count'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: PlanDetailStyle.paleGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${data.targets.length} target',
                    style: PlanDetailStyle.body.copyWith(
                      color: PlanDetailStyle.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            if (data.targets.isEmpty)
              const PlanDetailCard(
                child: Text(
                  'Belum ada target dalam periode ini.',
                  style: PlanDetailStyle.body,
                ),
              ),
          ],
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.builder(
          itemCount: data.targets.length,
          itemBuilder: (context, index) {
            final target = data.targets[index];
            return Padding(
              key: ValueKey('plan-target-${target.id}'),
              padding: const EdgeInsets.only(bottom: 14),
              child: TargetCard(
                target: target,
                onTap: () => _open(
                  '${widget.routePrefix}/targets/${Uri.encodeComponent(target.id)}',
                ),
              ),
            );
          },
        ),
      ),
      if (!widget.readOnly)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32 + MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverToBoxAdapter(
            child: FilledButton(
              key: const ValueKey('plan-add-target'),
              onPressed: () => _open(
                '/teacher/plans/${Uri.encodeComponent(data.plan.id)}/targets/new',
              ),
              child: const Text('Tambah target'),
            ),
          ),
        ),
      if (widget.readOnly)
        SliverToBoxAdapter(
          child: SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom),
        ),
    ],
  );
}
