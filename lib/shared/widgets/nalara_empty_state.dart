import 'package:flutter/material.dart';
import 'nalara_surface_card.dart';
import '../../utils/color.dart';

class NalaraEmptyState extends StatelessWidget {
  final String imagePath;
  final String message;
  final String? title;
  final double imageHeight;
  final Widget? action;

  const NalaraEmptyState({
    super.key,
    required this.imagePath,
    required this.message,
    this.title,
    this.imageHeight = 140,
    this.action,
  });

  @override
  Widget build(BuildContext context) => NalaraSurfaceCard(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          height: imageHeight,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 12),
        if (title != null) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: NalaraColors.ink,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 14,
            height: 1.45,
            color: NalaraColors.muted,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}
