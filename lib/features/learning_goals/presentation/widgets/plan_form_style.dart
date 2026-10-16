import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';

abstract final class PlanFormStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF155A49),
      ink = Color(0xFF101D2A),
      muted = Color(0xFF78828F),
      paleGreen = Color(0xFFECF3ED),
      line = Color(0xFFDDE1E6);
  static const artwork = 'assets/Empty/Empty target.png';
  static const label = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: ink,
  );
  static const supporting = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12.5,
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
      hintStyle: supporting,
      counterStyle: supporting.copyWith(fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: green, width: 1.4),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        backgroundColor: green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: green.withValues(alpha: .55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: label.copyWith(color: Colors.white, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        foregroundColor: green,
        side: const BorderSide(color: green, width: .7),
        shape: const StadiumBorder(),
        textStyle: label.copyWith(color: green),
      ),
    ),
  );
}

class PlanFormLabel extends StatelessWidget {
  final String text;
  final bool requiredField, optional;
  const PlanFormLabel(
    this.text, {
    super.key,
    this.requiredField = false,
    this.optional = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text.rich(
      TextSpan(
        text: text,
        children: [
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFE43D3D)),
            ),
          if (optional)
            const TextSpan(
              text: ' (opsional)',
              style: TextStyle(
                color: PlanFormStyle.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      style: PlanFormStyle.label,
    ),
  );
}

class PlanFormCard extends StatelessWidget {
  final Widget child;
  const PlanFormCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: NalaraCardStyle.border),
      boxShadow: const [
        BoxShadow(
          color: NalaraCardStyle.shadow,
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}
