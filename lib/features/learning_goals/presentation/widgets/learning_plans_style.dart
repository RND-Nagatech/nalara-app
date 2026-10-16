import 'package:flutter/material.dart';

abstract final class LearningPlansStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF155A49),
      ink = Color(0xFF111C25),
      muted = Color(0xFF6F7477),
      lightGreen = Color(0xFFE2F2E8);
  static const emptyArtwork = 'assets/Empty/Empty target.png';
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 25,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13.5,
    height: 1.5,
    color: muted,
  );
}
