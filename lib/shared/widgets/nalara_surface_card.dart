import 'package:flutter/material.dart';
import 'nalara_card_style.dart';

class NalaraSurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  const NalaraSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: NalaraCardStyle.decoration(radius: radius, color: color),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}
