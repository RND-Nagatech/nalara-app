import 'package:flutter/material.dart';
import '../../utils/color.dart';

/// Empty results sit directly on the page background, never in a surface card.
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
    this.imageHeight = 160,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 240,
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
      ),
    ),
  );
}
