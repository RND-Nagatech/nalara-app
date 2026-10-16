import 'package:flutter/material.dart';
import 'auth_palette.dart';

class RegisterBackdrop extends StatelessWidget {
  const RegisterBackdrop({super.key});
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _RegisterBackdropPainter());
}

class _RegisterBackdropPainter extends CustomPainter {
  const _RegisterBackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = AuthPalette.cream);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.69, -h * 0.08, w * 0.72, h * 0.28),
      Paint()..color = AuthPalette.green.withValues(alpha: 0.12),
    );
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.98, h * 0.175)
        ..quadraticBezierTo(w * 0.93, h * 0.1, w * 0.84, h * 0.07)
        ..quadraticBezierTo(w * 0.9, h * 0.15, w * 0.98, h * 0.175)
        ..moveTo(w * 0.98, h * 0.175)
        ..quadraticBezierTo(w * 1.005, h * 0.09, w * 0.94, h * 0.065)
        ..quadraticBezierTo(w * 0.94, h * 0.125, w * 0.98, h * 0.175),
      outline,
    );
    canvas.drawOval(
      Rect.fromLTWH(-w * 0.15, h * 0.92, w * 1.03, h * 0.27),
      Paint()..color = AuthPalette.green.withValues(alpha: 0.12),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.66, h * 0.91, w * 0.7, h * 0.25),
      Paint()..color = const Color(0xFFDCCCB4).withValues(alpha: 0.22),
    );
    canvas.drawOval(
      Rect.fromLTWH(-w * 0.48, h * 0.84, w * 0.73, h * 0.32),
      Paint()..color = const Color(0xFFB4BB98).withValues(alpha: 0.18),
    );
    final leaves = Paint()..color = AuthPalette.green.withValues(alpha: 0.58);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.01, h)
        ..quadraticBezierTo(-w * 0.05, h * 0.93, w * 0.105, h * 0.877)
        ..quadraticBezierTo(w * 0.105, h * 0.94, w * 0.01, h)
        ..close(),
      leaves,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.01, h)
        ..quadraticBezierTo(w * 0.025, h * 0.94, w * 0.2, h * 0.925)
        ..quadraticBezierTo(w * 0.165, h * 0.98, w * 0.01, h)
        ..close(),
      leaves..color = AuthPalette.green.withValues(alpha: 0.38),
    );
  }

  @override
  bool shouldRepaint(_RegisterBackdropPainter oldDelegate) => false;
}
