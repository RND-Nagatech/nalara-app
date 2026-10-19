import 'package:flutter/material.dart';
import '../../utils/color.dart';

/// An opaque, shared header surface. Its parent owns the system safe area.
class NalaraHeader extends StatelessWidget {
  final Widget child;
  final bool showDivider;

  /// Space inside the header, before its bottom divider. Never leave a fixed
  /// painted strip between the divider and the scrollable content viewport.
  final double bottomSpacing;
  const NalaraHeader({
    super.key,
    required this.child,
    this.showDivider = true,
    this.bottomSpacing = 14,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color:
        Scaffold.maybeOf(context)?.widget.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: NalaraColors.headerDivider,
          ),
      ],
    ),
  );
}

/// Keeps a naturally sized header above a separately scrollable page body.
class NalaraPageLayout extends StatelessWidget {
  final Widget header, body;

  /// Pinned tabs can own the divider at the bottom of the complete header.
  final bool showDivider;

  /// Passed to [NalaraHeader]; retained above the divider, not below it.
  final double bottomSpacing;
  const NalaraPageLayout({
    super.key,
    required this.header,
    required this.body,
    this.showDivider = true,
    this.bottomSpacing = 14,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      NalaraHeader(
        showDivider: showDivider,
        bottomSpacing: bottomSpacing,
        child: header,
      ),
      Expanded(child: body),
    ],
  );
}
