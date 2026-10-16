import 'package:flutter/material.dart';
import 'more_style.dart';

abstract final class HelpCenterStyle {
  static const cream = MoreStyle.cream,
      green = MoreStyle.green,
      ink = MoreStyle.ink,
      muted = Color(0xFF626D66),
      sage = MoreStyle.sage,
      line = Color(0xFFE4E8E2);
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.6,
    color: muted,
  );

  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(primary: green, onSurface: ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: body,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: green, width: 1.4),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: green,
        minimumSize: const Size(48, 44),
        textStyle: body.copyWith(color: green, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
