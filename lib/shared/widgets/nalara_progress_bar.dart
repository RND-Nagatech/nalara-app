import 'dart:math' as math;

import 'package:flutter/material.dart';

class NalaraProgressBar extends StatelessWidget {
  final int? progress;
  final String? semanticsLabel, emptyLabel;
  final Color fillColor, backgroundColor;
  final Color? accentColor;
  final double height;

  const NalaraProgressBar({
    super.key,
    required this.progress,
    required this.fillColor,
    required this.backgroundColor,
    this.accentColor = const Color(0xFFE6A143),
    this.semanticsLabel,
    this.emptyLabel,
    this.height = 9,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: progress == null ? emptyLabel : semanticsLabel,
    value: progress == null ? null : '${progress!.clamp(0, 100)} persen',
    child: ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final percentage = (progress ?? 0).clamp(0, 100).toDouble();
              final width = constraints.maxWidth * percentage / 100;
              final accentWidth = math.min(7.0, width);
              return Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: backgroundColor),
                  if (width > 0)
                    PositionedDirectional(
                      start: 0,
                      width: width,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        key: const ValueKey('nalara-progress-fill'),
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(height / 2),
                        ),
                      ),
                    ),
                  if (accentColor != null && width > 0 && percentage < 100)
                    PositionedDirectional(
                      start: width - accentWidth,
                      width: accentWidth,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        key: const ValueKey('nalara-progress-accent'),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(height / 2),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
