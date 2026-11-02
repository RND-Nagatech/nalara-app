import 'package:flutter/material.dart';

import 'auth_palette.dart';

/// Decorative curves stay behind the form and never receive pointer events.
class LoginBackdrop extends StatelessWidget {
  final bool showWaves;
  const LoginBackdrop({super.key, this.showWaves = true});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: CustomPaint(painter: _LoginBackdropPainter(showWaves: showWaves)),
    ),
  );
}

class _LoginBackdropPainter extends CustomPainter {
  final bool showWaves;
  const _LoginBackdropPainter({required this.showWaves});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final corner = width.clamp(0.0, 480.0);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      Path()
        ..moveTo(width - corner * 0.42, 0)
        ..cubicTo(
          width - corner * 0.35,
          corner * 0.15,
          width - corner * 0.15,
          corner * 0.10,
          width,
          corner * 0.29,
        )
        ..lineTo(width, 0)
        ..close(),
      Paint()..color = const Color(0xFFB4BB98).withValues(alpha: 0.20),
    );
    canvas.drawPath(
      Path()
        ..moveTo(width - corner * 0.32, 0)
        ..cubicTo(
          width - corner * 0.19,
          corner * 0.12,
          width - corner * 0.27,
          corner * 0.30,
          width,
          corner * 0.34,
        )
        ..lineTo(width, 0)
        ..close(),
      Paint()..color = AuthPalette.green.withValues(alpha: 0.065),
    );

    if (showWaves) {
      final waveHeight = (width * 0.18).clamp(60.0, 100.0);
      canvas.drawPath(
        Path()
          ..moveTo(0, height - waveHeight * 0.88)
          ..cubicTo(
            width * 0.20,
            height - waveHeight * 1.24,
            width * 0.33,
            height - waveHeight * 0.14,
            width * 0.53,
            height - waveHeight * 0.10,
          )
          ..cubicTo(
            width * 0.73,
            height - waveHeight * 0.17,
            width * 0.77,
            height - waveHeight * 0.98,
            width,
            height - waveHeight,
          )
          ..lineTo(width, height)
          ..lineTo(0, height)
          ..close(),
        Paint()..color = AuthPalette.green.withValues(alpha: 0.12),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, height - waveHeight * 0.45)
          ..cubicTo(
            width * 0.20,
            height - waveHeight * 0.77,
            width * 0.37,
            height - waveHeight * 0.08,
            width * 0.55,
            height - waveHeight * 0.12,
          )
          ..cubicTo(
            width * 0.73,
            height - waveHeight * 0.38,
            width * 0.87,
            height - waveHeight * 0.65,
            width,
            height - waveHeight * 0.31,
          )
          ..lineTo(width, height)
          ..lineTo(0, height)
          ..close(),
        Paint()..color = AuthPalette.green.withValues(alpha: 0.09),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoginBackdropPainter oldDelegate) =>
      oldDelegate.showWaves != showWaves;
}
