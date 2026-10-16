import 'package:flutter/material.dart';

abstract final class MoreStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF155A49),
      ink = Color(0xFF15242C),
      muted = Color(0xFF777D7F),
      sage = Color(0xFFEAF0E8),
      sand = Color(0xFFF8F0E2),
      orange = Color(0xFFCD6843),
      gold = Color(0xFFE8AD43);
  static const headerArtwork = 'assets/Icon/Icon lainnya.png';
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 25,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const subtitle = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12.5,
    height: 1.45,
    color: muted,
  );
}
