import 'package:flutter/material.dart';

import 'reports_style.dart';

abstract final class ReportDetailStyle {
  static const topic = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 22,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: ReportsStyle.ink,
  );
  static const heading = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: ReportsStyle.ink,
  );
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 14,
    height: 1.65,
    color: ReportsStyle.ink,
  );
  static const caption = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12.5,
    height: 1.5,
    color: ReportsStyle.muted,
  );

  static ThemeData theme(ThemeData base) => ReportsStyle.theme(base).copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ReportsStyle.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: heading.copyWith(fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ReportsStyle.ink,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: ReportsStyle.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: heading.copyWith(fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ReportsStyle.green,
        overlayColor: Colors.transparent,
        minimumSize: const Size(48, 44),
        textStyle: heading.copyWith(fontSize: 13),
      ),
    ),
  );
}
