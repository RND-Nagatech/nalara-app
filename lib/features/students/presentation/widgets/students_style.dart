import 'package:flutter/material.dart';

abstract final class StudentsStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF076347),
      ink = Color(0xFF1E292D),
      muted = Color(0xFF7B7F80),
      line = Color(0xFFEAE5DB),
      listDivider = Color(0xFFB7D8CA);
  static const emptyArtwork = 'assets/Empty/empty siswa.png';
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 27,
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
  static const tab = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
}
