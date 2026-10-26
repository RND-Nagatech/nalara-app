import 'package:flutter/material.dart';

abstract final class FamilyFormStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF155A49),
      ink = Color(0xFF1E292D),
      muted = Color(0xFF78808A),
      line = Color(0xFFDDE0E5),
      paleGreen = Color(0xFFEAF2E9);

  static const label = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 14,
    height: 1.4,
    color: ink,
  );

  static const input = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 14,
    height: 1.45,
    color: ink,
  );

  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 14,
    height: 1.5,
    color: muted,
  );

  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(
      primary: green,
      onSurface: ink,
      onSurfaceVariant: muted,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      hintStyle: input.copyWith(color: muted),
      counterStyle: input.copyWith(fontSize: 12, color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green, width: 1.4),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        backgroundColor: green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: green.withValues(alpha: .55),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'NalaraInter',
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
