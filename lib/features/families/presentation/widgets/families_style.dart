import 'package:flutter/material.dart';

abstract final class FamiliesStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF155A49),
      ink = Color(0xFF1E292D),
      muted = Color(0xFF7B7F80),
      line = Color(0xFFE5E5DF),
      sage = Color(0xFFE6EFE3);

  static const emptyArtwork = 'assets/Empty/Empty Keluarga.png';

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

  static const cardTitle = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(primary: green),
  );
}
