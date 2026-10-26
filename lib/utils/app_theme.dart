import 'package:flutter/material.dart';
import 'color.dart';

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'NalaraInter',
  colorScheme: ColorScheme.fromSeed(
    seedColor: NalaraColors.green,
    primary: NalaraColors.green,
    onPrimary: NalaraColors.surface,
    primaryContainer: NalaraColors.lightGreen,
    onPrimaryContainer: NalaraColors.green,
    secondary: NalaraColors.green,
    onSecondary: NalaraColors.surface,
    secondaryContainer: NalaraColors.lightGreen,
    onSecondaryContainer: NalaraColors.green,
    tertiary: NalaraColors.green,
    onTertiary: NalaraColors.surface,
    tertiaryContainer: NalaraColors.lightGreen,
    onTertiaryContainer: NalaraColors.green,
    surface: NalaraColors.surface,
    onSurface: NalaraColors.ink,
    onSurfaceVariant: NalaraColors.muted,
    surfaceContainerLowest: NalaraColors.surface,
    surfaceContainerLow: NalaraColors.cream,
    surfaceContainer: NalaraColors.cream,
    surfaceContainerHigh: NalaraColors.field,
    surfaceContainerHighest: NalaraColors.field,
    surfaceTint: Colors.transparent,
    outline: NalaraColors.line,
    outlineVariant: NalaraColors.line,
    error: NalaraColors.danger,
    onError: NalaraColors.surface,
    errorContainer: NalaraColors.errorSurface,
    onErrorContainer: NalaraColors.danger,
  ),
  scaffoldBackgroundColor: NalaraColors.cream,
  disabledColor: NalaraColors.disabled,
  dividerColor: NalaraColors.line,
  appBarTheme: const AppBarTheme(
    backgroundColor: NalaraColors.cream,
    foregroundColor: NalaraColors.ink,
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: 'NalaraInter',
      color: NalaraColors.ink,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: NalaraColors.ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: NalaraColors.ink,
    ),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: NalaraColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: NalaraColors.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: NalaraColors.ink),
    bodySmall: TextStyle(fontSize: 12, height: 1.5, color: NalaraColors.muted),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    margin: const EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: NalaraColors.line),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: NalaraColors.surface,
    border: _inputBorder,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: NalaraColors.line),
    ),
    focusedBorder: _inputBorder.copyWith(
      borderSide: const BorderSide(color: NalaraColors.green, width: 1.4),
    ),
    errorBorder: _inputBorder.copyWith(
      borderSide: const BorderSide(color: NalaraColors.danger),
    ),
    focusedErrorBorder: _inputBorder.copyWith(
      borderSide: const BorderSide(color: NalaraColors.danger, width: 1.4),
    ),
    labelStyle: const TextStyle(color: NalaraColors.muted, fontSize: 13),
    floatingLabelStyle: const TextStyle(
      color: NalaraColors.green,
      fontSize: 13,
    ),
    hintStyle: const TextStyle(color: NalaraColors.muted, fontSize: 14),
    counterStyle: const TextStyle(color: NalaraColors.muted, fontSize: 11),
    errorStyle: const TextStyle(color: NalaraColors.danger, height: 1.4),
    errorMaxLines: 3,
    prefixIconColor: NalaraColors.muted,
    suffixIconColor: NalaraColors.muted,
    contentPadding: const EdgeInsets.all(16),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: NalaraColors.green,
      foregroundColor: NalaraColors.surface,
      disabledBackgroundColor: NalaraColors.line,
      disabledForegroundColor: NalaraColors.muted,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: _actionLabel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: NalaraColors.green,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      textStyle: _actionLabel,
      side: const BorderSide(color: NalaraColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: NalaraColors.green,
      overlayColor: Colors.transparent,
      minimumSize: const Size(48, 48),
      textStyle: _actionLabel,
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: NalaraColors.green,
      overlayColor: Colors.transparent,
      minimumSize: const Size(44, 44),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: NalaraColors.green,
    foregroundColor: NalaraColors.surface,
    elevation: 2,
    extendedTextStyle: _actionLabel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    side: const BorderSide(color: NalaraColors.muted, width: 1.5),
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return NalaraColors.line;
      return states.contains(WidgetState.selected)
          ? NalaraColors.green
          : Colors.transparent;
    }),
    checkColor: const WidgetStatePropertyAll(NalaraColors.surface),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: const WidgetStatePropertyAll(NalaraColors.surface),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return NalaraColors.line;
      return states.contains(WidgetState.selected)
          ? NalaraColors.green
          : NalaraColors.disabled;
    }),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    thumbIcon: const WidgetStatePropertyAll(null),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: NalaraColors.green,
    linearTrackColor: NalaraColors.lightGreen,
    circularTrackColor: NalaraColors.lightGreen,
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: NalaraColors.green,
    inactiveTrackColor: NalaraColors.lightGreen,
    thumbColor: NalaraColors.green,
    valueIndicatorColor: NalaraColors.green,
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: NalaraColors.green,
    unselectedLabelColor: NalaraColors.muted,
    labelStyle: _actionLabel,
    indicatorColor: NalaraColors.green,
    dividerColor: NalaraColors.headerDivider,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: NalaraColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: _dialogShape,
    titleTextStyle: TextStyle(
      fontFamily: 'NalaraInter',
      color: NalaraColors.ink,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    contentTextStyle: TextStyle(
      fontFamily: 'NalaraInter',
      fontSize: 14,
      height: 1.5,
      color: NalaraColors.muted,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: NalaraColors.cream,
    modalBackgroundColor: NalaraColors.cream,
    surfaceTintColor: Colors.transparent,
    modalBarrierColor: NalaraColors.scrim,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    dragHandleColor: NalaraColors.disabled,
    dragHandleSize: Size(36, 4),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: NalaraColors.cream,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: _dialogShape,
    headerBackgroundColor: NalaraColors.cream,
    headerForegroundColor: NalaraColors.ink,
    headerHeadlineStyle: const TextStyle(
      fontFamily: 'NalaraInter',
      fontSize: 26,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    headerHelpStyle: _actionLabel.copyWith(
      fontSize: 12,
      color: NalaraColors.muted,
    ),
    weekdayStyle: _actionLabel.copyWith(
      fontSize: 12,
      color: NalaraColors.muted,
    ),
    dayStyle: const TextStyle(fontFamily: 'NalaraInter', fontSize: 13),
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return NalaraColors.disabled;
      return states.contains(WidgetState.selected)
          ? NalaraColors.surface
          : NalaraColors.ink;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? NalaraColors.green
          : Colors.transparent,
    ),
    todayForegroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? NalaraColors.surface
          : NalaraColors.green,
    ),
    todayBackgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? NalaraColors.green
          : NalaraColors.lightGreen,
    ),
    todayBorder: const BorderSide(color: NalaraColors.green),
    dividerColor: NalaraColors.line,
  ),
  timePickerTheme: TimePickerThemeData(
    backgroundColor: NalaraColors.cream,
    elevation: 0,
    shape: _dialogShape,
    helpTextStyle: _actionLabel.copyWith(
      color: NalaraColors.muted,
      fontSize: 12,
    ),
    hourMinuteColor: NalaraColors.surface,
    hourMinuteTextColor: NalaraColors.ink,
    hourMinuteTextStyle: const TextStyle(
      fontFamily: 'NalaraInter',
      fontSize: 36,
      fontWeight: FontWeight.w600,
    ),
    hourMinuteShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: NalaraColors.line),
    ),
    dialHandColor: NalaraColors.green,
    dialBackgroundColor: NalaraColors.lightGreen,
    dialTextColor: NalaraColors.ink,
    entryModeIconColor: NalaraColors.green,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: NalaraColors.surface,
      border: _inputBorder,
      enabledBorder: _inputBorder,
      contentPadding: EdgeInsets.all(12),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    indicatorColor: NalaraColors.lightGreen,
  ),
);

const _actionLabel = TextStyle(
  fontFamily: 'NalaraInter',
  fontSize: 14,
  fontWeight: FontWeight.w600,
  height: 1.4,
);
const _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(14)),
  borderSide: BorderSide(color: NalaraColors.line),
);
const _dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(24)),
  side: BorderSide(color: NalaraColors.line),
);
