import 'package:flutter/material.dart';

abstract final class NotificationsStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF155A49),
      ink = Color(0xFF15242C),
      muted = Color(0xFF626D66),
      sage = Color(0xFFEAF0E8),
      line = Color(0xFFE5EAE3),
      unreadLine = Color(0xFFBDD4C4);
  static const emptyArtwork = 'assets/Icon/Icon laporan belum selesai.png';
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.55,
    color: muted,
  );

  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(primary: green, onSurface: ink),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: green,
        minimumSize: const Size(48, 44),
        textStyle: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static ButtonStyle get roundButton => IconButton.styleFrom(
    minimumSize: const Size(44, 44),
    foregroundColor: green,
    shape: const CircleBorder(),
  );
}
