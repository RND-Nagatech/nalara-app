import 'package:flutter/material.dart';
import 'more_style.dart';

abstract final class ProfileStyle {
  static const cream = MoreStyle.cream,
      green = MoreStyle.green,
      ink = MoreStyle.ink,
      sage = MoreStyle.sage,
      muted = Color(0xFF626E67),
      line = Color(0xFFE5E9E0),
      paper = Color(0xFFFFFEFB),
      danger = Color(0xFF9B493E);

  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 14,
    height: 1.55,
    color: muted,
  );

  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(
      primary: green,
      onSurface: ink,
      error: danger,
    ),
  );
}
