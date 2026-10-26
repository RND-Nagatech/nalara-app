import 'package:flutter/material.dart';
import 'nalara_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../state/load_cubit.dart';
import '../state/teaching_catalog_refresh.dart';
import '../domain/page.dart';
import '../../utils/color.dart';
import 'feedback_notice.dart';
import 'nalara_load_more.dart';
import 'nalara_empty_state.dart';
import 'nalara_page_header.dart';
import 'nalara_error_notice.dart';
import 'nalara_dialog.dart';

export 'nalara_error_notice.dart';

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: children,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionTitle(this.title, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    ),
  );
}

class EmptyNotice extends StatelessWidget {
  final String message;
  final Widget? action;
  final String? imagePath;
  const EmptyNotice(this.message, {super.key, this.action, this.imagePath});
  @override
  Widget build(BuildContext context) => NalaraEmptyState(
    imagePath: imagePath ?? 'assets/Empty/empty siswa.png',
    message: message,
    action: action,
  );
}

class AsyncPage<T> extends StatefulWidget {
  final String title;
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, VoidCallback) builder;
  final List<Widget>? actions;
  final bool refreshOnCatalogChange;
  const AsyncPage({
    super.key,
    required this.title,
    required this.load,
    required this.builder,
    this.actions,
    this.refreshOnCatalogChange = false,
  });
  @override
  State<AsyncPage<T>> createState() => _AsyncPageState<T>();
}

class _AsyncPageState<T> extends State<AsyncPage<T>>
    with TeachingCatalogRefresh<AsyncPage<T>> {
  late final LoadCubit<T> cubit = LoadCubit<T>(() => widget.load())..load();
  @override
  void onTeachingCatalogChanged() {
    if (widget.refreshOnCatalogChange) cubit.load();
  }

  @override
  void didUpdateWidget(covariant AsyncPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.load != widget.load) cubit.load();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NalaraColors.cream,
    body: Column(
      children: [
        NalaraHeader(
          child: NalaraPageHeader(
            title: widget.title,
            actions: widget.actions ?? const [],
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: BlocBuilder<LoadCubit<T>, LoadState<T>>(
              bloc: cubit,
              builder: (context, state) {
                if (state.status == LoadStatus.error) {
                  return ErrorNotice(state.error!, retry: cubit.load);
                }
                if (state.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: widget.builder(context, state.value as T, cubit.load),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

class PagedListPage<T> extends StatefulWidget {
  final String title, empty;
  final String? emptyArtwork;
  final bool Function(T item)? itemFilter;
  final Future<PageResult<T>> Function(int) load;
  final Widget Function(BuildContext, T, VoidCallback) itemBuilder;
  final List<Widget> Function(VoidCallback)? controls;
  final String? newRoute;
  final bool refreshOnCatalogChange, showFloatingActionButton;
  final double emptyVerticalOffset;
  const PagedListPage({
    super.key,
    required this.title,
    required this.empty,
    this.emptyArtwork,
    this.itemFilter,
    required this.load,
    required this.itemBuilder,
    this.controls,
    this.newRoute,
    this.refreshOnCatalogChange = false,
    this.showFloatingActionButton = true,
    this.emptyVerticalOffset = 0,
  });
  @override
  State<PagedListPage<T>> createState() => _PagedListPageState<T>();
}

class _PagedListPageState<T> extends State<PagedListPage<T>>
    with TeachingCatalogRefresh<PagedListPage<T>> {
  int page = 1;
  late final LoadCubit<PageResult<T>> cubit = LoadCubit<PageResult<T>>(
    () => widget.load(page),
    isEmpty: (value) => _visibleItems(value).isEmpty,
    append: appendPage,
  )..load();

  List<T> _visibleItems(PageResult<T> result) => result.items
      .where(widget.itemFilter ?? (_) => true)
      .toList(growable: false);
  @override
  void onTeachingCatalogChanged() {
    if (widget.refreshOnCatalogChange) _refresh();
  }

  Future<void> _refresh() {
    page = 1;
    return cubit.load();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  Future<void> add() async {
    await context.push(widget.newRoute!);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NalaraColors.cream,
    floatingActionButton:
        widget.newRoute == null || !widget.showFloatingActionButton
        ? null
        : FloatingActionButton.extended(
            heroTag: 'nalara-paged-list-${widget.newRoute ?? widget.title}',
            onPressed: add,
            icon: const Icon(Icons.add),
            label: const Text('Tambah'),
          ),
    body: Column(
      children: [
        NalaraHeader(
          child: NalaraPageHeader(
            title: widget.title,
            actions: [
              IconButton(
                onPressed: _refresh,
                tooltip: 'Muat ulang',
                style: IconButton.styleFrom(
                  fixedSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  foregroundColor: NalaraColors.green,
                  overlayColor: Colors.transparent,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 25),
              ),
            ],
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child:
                BlocBuilder<LoadCubit<PageResult<T>>, LoadState<PageResult<T>>>(
                  bloc: cubit,
                  builder: (context, state) {
                    final visibleItems = state.value == null
                        ? <T>[]
                        : _visibleItems(state.value!);
                    if (state.status == LoadStatus.error) {
                      return ErrorNotice(state.error!, retry: _refresh);
                    }
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: CustomScrollView(
                            physics: state.status == LoadStatus.empty
                                ? const NeverScrollableScrollPhysics()
                                : const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  0,
                                ),
                                sliver: SliverList.list(
                                  children: [
                                    ...?widget.controls?.call(() {
                                      page = 1;
                                      cubit.load();
                                    }),
                                    if (state.status == LoadStatus.loading ||
                                        state.value == null)
                                      const LinearProgressIndicator(),
                                  ],
                                ),
                              ),
                              if (state.status == LoadStatus.empty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      widget.emptyVerticalOffset,
                                    ),
                                    child: EmptyNotice(
                                      widget.empty,
                                      imagePath: widget.emptyArtwork,
                                      action: state.value?.hasNext == true
                                          ? FilledButton(
                                              onPressed: () {
                                                page++;
                                                cubit.load(append: true);
                                              },
                                              child: const Text(
                                                'Muat lebih banyak',
                                              ),
                                            )
                                          : widget.newRoute == null
                                          ? null
                                          : FilledButton(
                                              onPressed: add,
                                              child: const Text(
                                                'Tambah sekarang',
                                              ),
                                            ),
                                    ),
                                  ),
                                )
                              else if (state.value != null)
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  sliver: SliverList.builder(
                                    itemCount: visibleItems.length,
                                    itemBuilder: (context, index) =>
                                        widget.itemBuilder(
                                          context,
                                          visibleItems[index],
                                          cubit.load,
                                        ),
                                  ),
                                ),
                              if (state.value != null && state.value!.total > 0)
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    18,
                                    20,
                                    70,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: NalaraLoadMoreButton(
                                      hasMore: state.value!.hasNext,
                                      loading:
                                          state.status == LoadStatus.loading,
                                      onPressed: () {
                                        page++;
                                        cubit.load(append: true);
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    ),
  );
}

class SubmitButton extends StatelessWidget {
  final SubmitCubit cubit;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  const SubmitButton({
    super.key,
    required this.cubit,
    required this.onPressed,
    this.label = 'Simpan',
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: cubit,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton(
          onPressed: state.busy || !enabled ? null : onPressed,
          child: state.busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        ),
      ],
    ),
  );
}

Future<bool> confirmAction(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: NalaraColors.scrim,
      builder: (context) => NalaraDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Konfirmasi',
              style: TextStyle(
                fontFamily: 'NalaraInter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: NalaraColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'NalaraInter',
                fontSize: 13.5,
                height: 1.5,
                color: NalaraColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowSpacing: 8,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Lanjutkan'),
                ),
              ],
            ),
          ],
        ),
      ),
    ) ??
    false;
void successMessage(BuildContext context, String message) =>
    showNalaraNotice(context, message);
void errorMessage(BuildContext context, String message) => showNalaraNotice(
  context,
  message,
  type: NalaraNoticeType.error,
  title: 'Periksa kembali',
);

class DetailRow extends StatelessWidget {
  final String label, value;
  const DetailRow(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: NalaraColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value.isEmpty ? '—' : value),
      ],
    ),
  );
}
