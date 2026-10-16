import 'package:flutter/material.dart';

/// Shared surface treatment for content cards across the teacher app.
///
/// The solid surface, fine border, and short soft shadow make card boundaries
/// clear on the cream background without turning every section into a heavy
/// floating panel.
abstract final class NalaraCardStyle {
  static const border = Color(0xFFE4E2D9);
  static const shadow = Color(0x146D6A56);

  static BoxDecoration decoration({
    double radius = 18,
    Color color = Colors.white,
    Color borderColor = border,
  }) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: const [
      BoxShadow(color: shadow, blurRadius: 16, offset: Offset(0, 5)),
    ],
  );
}
