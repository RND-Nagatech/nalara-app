import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'students_style.dart';

class StudentListProgressBar extends StatelessWidget {
  final int? progress;
  final String emptyLabel;

  const StudentListProgressBar({
    super.key,
    required this.progress,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: progress == null ? emptyLabel : 'Progres minggu ini',
    value: progress == null ? null : '$progress persen',
    child: ExcludeSemantics(
      child: SizedBox(
        height: 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  constraints.maxWidth * (progress ?? 0).clamp(0, 100) / 100;
              final accentWidth = math.min(7.0, width);
              return Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFFFAE8D9)),
                  if (width > 0)
                    PositionedDirectional(
                      start: 0,
                      width: width,
                      top: 0,
                      bottom: 0,
                      child: const ColoredBox(color: StudentsStyle.green),
                    ),
                  if (width > 0 && progress! < 100)
                    PositionedDirectional(
                      start: width - accentWidth,
                      width: accentWidth,
                      top: 0,
                      bottom: 0,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFE6A143),
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(5),
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
