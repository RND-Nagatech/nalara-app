import 'package:flutter/material.dart';
import '../../../../shared/domain/page.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/nalara_error_notice.dart';
import '../../../../shared/widgets/nalara_load_more.dart';
import '../../domain/entities/family.dart';
import 'families_empty_state.dart';
import 'families_style.dart';
import 'family_list_card.dart';

class FamiliesListBody extends StatelessWidget {
  final LoadState<PageResult<Family>> state;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry, onAdd;
  final ValueChanged<Family> onOpen;
  final VoidCallback onLoadMore;

  const FamiliesListBody({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onAdd,
    required this.onOpen,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final data = state.value;
    final failure = ErrorNotice(
      state.error ?? 'Data keluarga belum dapat dimuat.',
      retry: onRetry,
      retryKey: const ValueKey('families-retry'),
      compact: data?.items.isNotEmpty ?? false,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: FamiliesStyle.green,
      child: CustomScrollView(
        key: const PageStorageKey('families-list'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (state.status == LoadStatus.loading && data != null)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                color: FamiliesStyle.green,
                minHeight: 2,
              ),
            ),
          if (data == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: state.error != null
                    ? failure
                    : const CircularProgressIndicator(
                        color: FamiliesStyle.green,
                      ),
              ),
            )
          else if (state.error != null && data.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: failure),
            )
          else if (data.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: FamiliesEmptyState(onAdd: onAdd)),
            )
          else ...[
            if (state.error != null) SliverToBoxAdapter(child: failure),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList.builder(
                itemCount: data.items.length * 2 - 1,
                itemBuilder: (context, index) {
                  if (index.isOdd) return const SizedBox(height: 10);
                  final family = data.items[index ~/ 2];
                  return FamilyListCard(
                    key: ValueKey(family.id),
                    family: family,
                    onTap: () => onOpen(family),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              sliver: SliverToBoxAdapter(
                child: NalaraLoadMoreButton(
                  hasMore: data.hasNext,
                  loading: state.status == LoadStatus.loading,
                  onPressed: onLoadMore,
                  buttonKey: const ValueKey('families-load-more'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
