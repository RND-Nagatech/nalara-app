import 'package:flutter/material.dart';
import '../../../../shared/domain/page.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/nalara_load_more.dart';
import '../../domain/entities/lesson_report.dart';
import 'report_list_card.dart';
import 'reports_empty_state.dart';
import 'reports_style.dart';

class ReportsTabBody extends StatelessWidget {
  final String? status;
  final LoadState<PageResult<LessonReport>> state;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry, onAdd;
  final ValueChanged<LessonReport> onOpen;
  final VoidCallback onLoadMore;
  final bool readOnly;

  const ReportsTabBody({
    super.key,
    required this.status,
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onAdd,
    required this.onOpen,
    required this.onLoadMore,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final data = state.value;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ReportsStyle.green,
      child: CustomScrollView(
        key: PageStorageKey('reports-list-${status ?? 'all'}'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          if (state.status == LoadStatus.loading && data != null)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                color: ReportsStyle.green,
                minHeight: 2,
              ),
            ),
          if (data == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: state.status == LoadStatus.error
                    ? _error(
                        state.error ?? 'Laporan belum dapat dimuat.',
                        onRetry,
                      )
                    : const CircularProgressIndicator(
                        color: ReportsStyle.green,
                      ),
              ),
            )
          else if (state.status == LoadStatus.error && data.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: _error(
                  state.error ?? 'Laporan belum dapat dimuat.',
                  onRetry,
                ),
              ),
            )
          else if (data.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ReportsEmptyState(
                  status: status,
                  onAdd: onAdd,
                  showAction: !readOnly,
                ),
              ),
            )
          else ...[
            if (state.status == LoadStatus.error)
              SliverToBoxAdapter(
                child: _error(
                  state.error ?? 'Laporan belum dapat dimuat.',
                  onRetry,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              sliver: SliverList.builder(
                itemCount: data.items.length,
                itemBuilder: (context, index) {
                  final report = data.items[index];
                  return ReportListCard(
                    key: ValueKey(report.id),
                    report: report,
                    onTap: () => onOpen(report),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 90),
              sliver: SliverToBoxAdapter(
                child: NalaraLoadMoreButton(
                  hasMore: data.hasNext,
                  loading: state.status == LoadStatus.loading,
                  onPressed: onLoadMore,
                  buttonKey: ValueKey('reports-load-more-${status ?? 'all'}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _error(String message, VoidCallback retry) => Padding(
    padding: const EdgeInsets.all(22),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center, style: ReportsStyle.body),
        const SizedBox(height: 12),
        TextButton(onPressed: retry, child: const Text('Coba lagi')),
      ],
    ),
  );
}
