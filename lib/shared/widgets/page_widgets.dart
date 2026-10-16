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
import 'nalara_page_header.dart';
import 'nalara_surface_card.dart';

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
  Widget build(BuildContext context) => Align(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: NalaraSurfaceCard(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              )
            else
              const Icon(
                Icons.menu_book_outlined,
                size: 42,
                color: NalaraColors.green,
              ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null)
              Padding(padding: const EdgeInsets.only(top: 16), child: action!),
          ],
        ),
      ),
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const ErrorNotice(this.message, {super.key, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: EmptyNotice(
      message,
      action: FilledButton.icon(
        onPressed: retry,
        icon: const Icon(Icons.refresh),
        label: const Text('Coba lagi'),
      ),
    ),
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
  final Future<PageResult<T>> Function(int) load;
  final Widget Function(BuildContext, T, VoidCallback) itemBuilder;
  final List<Widget> Function(VoidCallback)? controls;
  final String? newRoute;
  final bool refreshOnCatalogChange;
  const PagedListPage({
    super.key,
    required this.title,
    required this.empty,
    this.emptyArtwork,
    required this.load,
    required this.itemBuilder,
    this.controls,
    this.newRoute,
    this.refreshOnCatalogChange = false,
  });
  @override
  State<PagedListPage<T>> createState() => _PagedListPageState<T>();
}

class _PagedListPageState<T> extends State<PagedListPage<T>>
    with TeachingCatalogRefresh<PagedListPage<T>> {
  int page = 1;
  late final LoadCubit<PageResult<T>> cubit = LoadCubit<PageResult<T>>(
    () => widget.load(page),
    isEmpty: (value) => value.items.isEmpty,
    append: appendPage,
  )..load();
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
    floatingActionButton: widget.newRoute == null
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
                    if (state.status == LoadStatus.error) {
                      return ErrorNotice(state.error!, retry: _refresh);
                    }
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: PageBody(
                        children: [
                          ...?widget.controls?.call(() {
                            page = 1;
                            cubit.load();
                          }),
                          if (state.status == LoadStatus.loading ||
                              state.value == null)
                            const LinearProgressIndicator(),
                          if (state.status == LoadStatus.empty)
                            EmptyNotice(
                              widget.empty,
                              imagePath: widget.emptyArtwork,
                              action: widget.newRoute == null
                                  ? null
                                  : FilledButton(
                                      onPressed: add,
                                      child: const Text('Tambah sekarang'),
                                    ),
                            ),
                          if (state.value != null)
                            ...state.value!.items.map(
                              (item) =>
                                  widget.itemBuilder(context, item, cubit.load),
                            ),
                          if (state.value != null && state.value!.total > 0)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 18,
                                bottom: 70,
                              ),
                              child: NalaraLoadMoreButton(
                                hasMore: state.value!.hasNext,
                                loading: state.status == LoadStatus.loading,
                                onPressed: () {
                                  page++;
                                  cubit.load(append: true);
                                },
                              ),
                            ),
                        ],
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
  const SubmitButton({
    super.key,
    required this.cubit,
    required this.onPressed,
    this.label = 'Simpan',
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
          onPressed: state.busy ? null : onPressed,
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
      barrierColor: Colors.black.withValues(alpha: .16),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: NalaraSurfaceCard(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          radius: 20,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Lanjutkan'),
                  ),
                ],
              ),
            ],
          ),
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
