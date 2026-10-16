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
          'Google',
          const SizedBox.square(
            dimension: 22,
            child: CustomPaint(painter: _GoogleMark()),
          ),
          onPressed: onGooglePressed,
        ),
      ),
    ],
  );

  Widget _option(String label, Widget icon, {VoidCallback? onPressed}) =>
      Tooltip(
        message: 'Masuk dengan $label',
        child: OutlinedButton.icon(
          key: ValueKey('auth-social-${label.toLowerCase()}'),
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            disabledForegroundColor: AuthPalette.ink,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: icon,
          label: Text(label),
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
