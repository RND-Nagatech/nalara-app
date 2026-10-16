import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../../shared/widgets/nalara_load_more.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_filter.dart';
import '../bloc/students_cubit.dart';
import 'student_list_card.dart';
import 'students_empty_state.dart';
import 'students_style.dart';

class StudentsTabBody extends StatelessWidget {
  final StudentFilter filter;
  final StudentListState value;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry, onAdd;
  final ValueChanged<Student> onOpen;
  final VoidCallback onLoadMore;
  final bool readOnly;
  const StudentsTabBody({
    super.key,
    required this.filter,
    required this.value,
    required this.onRefresh,
    required this.onRetry,
    required this.onAdd,
    required this.onOpen,
    required this.onLoadMore,
    this.readOnly = false,
  });
  @override
  Widget build(BuildContext context) {
    final data = value.data;
    final failure = Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.error ?? '',
            textAlign: TextAlign.center,
            style: StudentsStyle.body,
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: StudentsStyle.green,
      child: CustomScrollView(
        key: PageStorageKey('students-list-${filter.name}'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          if (value.loading && data != null)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                color: StudentsStyle.green,
                minHeight: 2,
              ),
            ),
          if (data == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: value.error != null
                    ? failure
                    : const CircularProgressIndicator(
                        color: StudentsStyle.green,
                      ),
              ),
            )
          else if (value.error != null && data.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: failure),
            )
          else if (data.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: StudentsEmptyState(onAdd: onAdd, showAction: !readOnly),
              ),
            )
          else ...[
            if (value.error != null) SliverToBoxAdapter(child: failure),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: NalaraCardStyle.decoration(radius: 18),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var index = 0; index < data.items.length; index++)
                          Column(
                            children: [
                              StudentListCard(
                                key: ValueKey(data.items[index].id),
                                student: data.items[index],
                                onTap: () => onOpen(data.items[index]),
                              ),
                              if (index < data.items.length - 1)
                                const Padding(
                                  padding: EdgeInsets.only(left: 86, right: 14),
                                  child: Divider(
                                    height: 1,
                                    color: StudentsStyle.listDivider,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
              sliver: SliverToBoxAdapter(
                child: NalaraLoadMoreButton(
                  hasMore: data.hasNext,
                  loading: value.loading,
                  onPressed: onLoadMore,
                  buttonKey: ValueKey('students-load-more-${filter.name}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
