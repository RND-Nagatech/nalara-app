import 'package:flutter/material.dart';

abstract final class ReportsStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF076347),
      ink = Color(0xFF1E292D),
      muted = Color(0xFF7B7F80),
      line = Color(0xFFEAE5DB),
      orange = Color(0xFFA75B24),
      sage = Color(0xFFE6EFE3),
      sand = Color(0xFFF5EBDD);
  static const emptyArtwork = 'assets/Icon/Icon laporan belum selesai.png';
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13.5,
    height: 1.5,
    color: muted,
  );
  static const tab = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  static ButtonStyle get roundButton => IconButton.styleFrom(
    minimumSize: const Size(44, 44),
    foregroundColor: green,
    shape: const CircleBorder(),
  );

  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(primary: green, onSurface: ink),
  );
}
