import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/domain/page.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/widgets/nalara_load_more.dart';
import '../../../../shared/widgets/nalara_error_notice.dart';
import '../../../../utils/injector.dart';
import '../../../teaching_guide/presentation/teaching_tutorial_scope.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/repositories/learning_repository.dart';
import '../../domain/usecases/update_progress.dart';
import '../bloc/learning_plans_cubit.dart';
import '../widgets/learning_plans_grouped_list.dart';
import '../widgets/learning_plans_empty_state.dart';
import '../widgets/learning_plans_style.dart';

class LearningPlansPage extends StatefulWidget {
  final String? studentId;
  final Future<PageResult<LearningPlan>> Function(int page, String? studentId)?
  loadPlans;
  final bool readOnly;
  final String routePrefix;
  final String? subtitle;
  const LearningPlansPage({
    super.key,
    this.studentId,
    this.loadPlans,
    this.readOnly = false,
    this.routePrefix = '/teacher',
    this.subtitle,
  }) : assert(!readOnly || loadPlans != null);

  @override
  State<LearningPlansPage> createState() => _LearningPlansPageState();
}

class _LearningPlansPageState extends State<LearningPlansPage>
    with TeachingCatalogRefresh<LearningPlansPage> {
  late LearningPlansCubit _cubit;
  @override
  void onTeachingCatalogChanged() => _cubit.refresh();
  @override
  void initState() {
    super.initState();
    _createCubit();
  }

  void _createCubit() {
    final loadPlans = widget.loadPlans;
    _cubit =
        (loadPlans == null
              ? LearningPlansCubit(
                  getIt<LearningRepository>(),
                  studentId: widget.studentId,
                )
              : LearningPlansCubit.withLoader(
                  loadPlans,
                  studentId: widget.studentId,
                ))
          ..refresh();
  }

  @override
  void didUpdateWidget(covariant LearningPlansPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.studentId != oldWidget.studentId ||
        widget.loadPlans != oldWidget.loadPlans) {
      _cubit.close();
      _createCubit();
    }
  }

  Future<void> _open(String route) async {
    final cubit = _cubit;
    await context.push(route);
    if (mounted && identical(cubit, _cubit)) await cubit.refresh();
  }

  void _add() => _open(
    Uri(
      path: '/teacher/targets/new',
      queryParameters: widget.studentId == null
          ? null
          : {'studentId': widget.studentId!},
    ).toString(),
  );

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'NalaraInter'),
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: LearningPlansStyle.green),
      ),
      child: BlocBuilder<LearningPlansCubit, LearningPlansState>(
        bloc: _cubit,
        builder: (context, state) => Scaffold(
          backgroundColor: LearningPlansStyle.cream,
          floatingActionButton:
              !widget.readOnly && state.result?.items.isNotEmpty == true
              ? TutorialTarget(
                  id: 'add-target',
                  child: FloatingActionButton.extended(
                    key: const ValueKey('target-add-list'),
                    heroTag: 'target-add-list',
                    onPressed: _add,
                    backgroundColor: LearningPlansStyle.green,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: LearningPlansStyle.green,
              onRefresh: _cubit.refresh,
              child: NalaraPageLayout(
                header: _header(state),
                body: CustomScrollView(
                  key: const ValueKey('target-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (state.loading && state.result != null)
                      const SliverToBoxAdapter(
                        child: LinearProgressIndicator(
                          color: LearningPlansStyle.green,
                          backgroundColor: LearningPlansStyle.lightGreen,
                        ),
                      ),
                    if (state.error != null)
                      SliverToBoxAdapter(child: _error(state.error!)),
                    if (state.result == null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: state.loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: LearningPlansStyle.green,
                                ),
                              )
                            : const SizedBox.shrink(),
                      )
                    else if (state.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: LearningPlansEmptyState(
                            onAdd: _add,
                            showAction: !widget.readOnly,
                            description: widget.readOnly
                                ? 'Rencana dan target belajar dari Guru akan muncul di sini.'
                                : null,
                          ),
                        ),
                      )
                    else if (state.result!.items.isNotEmpty)
                      _plans(state.result!)
                    else if (!state.loading && state.error == null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: LearningPlansEmptyState(
                            onAdd: _add,
                            showAction: !widget.readOnly,
                          ),
                        ),
                      ),
                    if (state.result != null && state.result!.total > 0)
                      SliverToBoxAdapter(child: _pagination(state)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header(LearningPlansState state) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.studentId != null)
          IconButton(
            tooltip: 'Kembali ke siswa',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(
                  '${widget.routePrefix}/students/${Uri.encodeComponent(widget.studentId!)}',
                );
              }
            },
            icon: const Icon(Icons.arrow_back, color: LearningPlansStyle.green),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target belajar', style: LearningPlansStyle.title),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle ??
                        (widget.readOnly
                            ? 'Lihat rencana dan target belajar anak'
                            : 'Kelola rencana dan target belajar siswa'),
                    style: LearningPlansStyle.body,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('target-refresh'),
              tooltip: 'Muat ulang target',
              onPressed: state.loading ? null : _cubit.refresh,
              style: IconButton.styleFrom(
                foregroundColor: LearningPlansStyle.green,
                minimumSize: const Size(40, 40),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 26),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _plans(PageResult<LearningPlan> result) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    sliver: LearningPlansGroupedList(
      plans: result.items,
      progressLabel: (plan) => PlanProgressLabel()(plan),
      onOpen: (plan) =>
          _open('${widget.routePrefix}/plans/${Uri.encodeComponent(plan.id)}'),
    ),
  );

  Widget _pagination(LearningPlansState state) {
    final result = state.result!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: NalaraLoadMoreButton(
        buttonKey: const ValueKey('target-load-more'),
        hasMore: result.hasNext,
        loading: state.loading,
        onPressed: _cubit.loadMore,
      ),
    );
  }

  Widget _error(String message) => ErrorNotice(
    message,
    retry: _cubit.retry,
    retryKey: const ValueKey('target-retry'),
    compact: _cubit.state.result?.items.isNotEmpty ?? false,
  );
}
