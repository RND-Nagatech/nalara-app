import 'package:flutter/material.dart';

abstract final class ScheduleFormStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF155A49),
      ink = Color(0xFF142027),
      muted = Color(0xFF74808A),
      paleGreen = Color(0xFFE8F1EB),
      line = Color(0xFFE0E5E8);
  static const artwork = 'assets/Icon/Icon lainnya.png';
  static const label = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13.5,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: ink,
  );
  static const supporting = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12,
    height: 1.45,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: green, width: 1.4),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: green.withValues(alpha: .55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(
          fontFamily: 'NalaraInter',
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
