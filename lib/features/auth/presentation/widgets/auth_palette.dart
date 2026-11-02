import 'package:flutter/material.dart';

class AuthPalette {
  static const cream = Color(0xFFF5F2E9);
  static const loginCream = Color(0xFFFAF8F4);
  static const green = Color(0xFF2C624B);
  static const ink = Color(0xFF252A28);
  static const muted = Color(0xFF757D7D);
  static const line = Color(0xFFD8D6CE);

  static Color get loginWaveBase => Color.alphaBlend(
    green.withValues(alpha: 0.09),
    Color.alphaBlend(green.withValues(alpha: 0.12), loginCream),
  );
}
