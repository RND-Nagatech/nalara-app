import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'more_style.dart';

class MoreHeader extends StatelessWidget {
  const MoreHeader({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(12.5) > 18;
        const intro = Column(
          key: ValueKey('more-header-intro'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lainnya', style: MoreStyle.title),
            SizedBox(height: 6),
            Text(
              'Kelola fitur dan pengaturan akun Anda',
              style: MoreStyle.subtitle,
            ),
          ],
        );
        final artwork = IgnorePointer(
          child: Image.asset(
            MoreStyle.headerArtwork,
            key: const ValueKey('more-header-artwork'),
            width: math.min(152, constraints.maxWidth * (stacked ? .45 : .4)),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        );
        // Give each element its own space, including at large text scales.
        return stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  intro,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: artwork),
                ],
              )
            : Row(
                children: [
                  const Expanded(child: intro),
                  const SizedBox(width: 16),
                  artwork,
                ],
              );
      },
    ),
  );
}
