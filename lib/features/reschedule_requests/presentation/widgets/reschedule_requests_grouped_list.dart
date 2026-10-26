import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';

/// Sliver rows stay lazy as load-more appends to one rounded surface.
class RescheduleRequestsGroupedList extends StatelessWidget {
  final int itemCount;
  final Widget Function(
    BuildContext context,
    int index,
    BorderRadius radius,
    bool divider,
  )
  itemBuilder;
  const RescheduleRequestsGroupedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) => DecoratedSliver(
    key: const ValueKey('reschedule-requests-group'),
    decoration: NalaraCardStyle.decoration(radius: 18),
    sliver: SliverPadding(
      padding: const EdgeInsets.all(1),
      sliver: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) => itemBuilder(
          context,
          index,
          BorderRadius.vertical(
            top: index == 0 ? const Radius.circular(17) : Radius.zero,
            bottom: index == itemCount - 1
                ? const Radius.circular(17)
                : Radius.zero,
          ),
          index < itemCount - 1,
        ),
      ),
    ),
  );
}
