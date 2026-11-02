import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'auth_palette.dart';

/// Google is enabled here; Apple remains hidden until its provider is needed.
class SocialLoginOptions extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  const SocialLoginOptions({super.key, this.onGooglePressed});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _option(
          const SizedBox.square(
            dimension: 24,
            child: CustomPaint(painter: _GoogleMark()),
          ),
          onPressed: onGooglePressed,
        ),
      ),
    ],
  );

  Widget _option(Widget icon, {VoidCallback? onPressed}) => Tooltip(
    message: 'Masuk dengan Google',
    child: OutlinedButton.icon(
      key: const ValueKey('auth-social-google'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        foregroundColor: AuthPalette.ink,
        disabledForegroundColor: AuthPalette.ink,
        elevation: 2,
        shadowColor: AuthPalette.ink.withValues(alpha: 0.09),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'NalaraInter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: icon,
      label: const Text('Masuk dengan Google'),
    ),
  );
}

class _GoogleMark extends CustomPainter {
  const _GoogleMark();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.12,
      size.width * 0.76,
      size.height * 0.76,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18;
    canvas.drawArc(
      rect,
      -math.pi * 0.26,
      -math.pi * 0.51,
      false,
      paint..color = const Color(0xFFEA4335),
    );
    canvas.drawArc(
      rect,
      -math.pi * 0.77,
      -math.pi * 0.46,
      false,
      paint..color = const Color(0xFFFBBC05),
    );
    canvas.drawArc(
      rect,
      -math.pi * 1.23,
      -math.pi * 0.52,
      false,
      paint..color = const Color(0xFF34A853),
    );
    canvas.drawArc(
      rect,
      math.pi * 0.25,
      -math.pi * 0.25,
      false,
      paint..color = const Color(0xFF4285F4),
    );
    canvas.drawLine(
      Offset(size.width * 0.88, size.height * 0.5),
      Offset(size.width * 0.51, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoogleMark oldDelegate) => false;
}
