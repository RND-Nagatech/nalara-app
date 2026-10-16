import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';

abstract final class StudentDetailStyle {
  static const cream = Color(0xFFFBF8F2),
      green = Color(0xFF155A49),
      ink = Color(0xFF10182B),
      muted = Color(0xFF7A7F89),
      paleGreen = Color(0xFFEBF2E9);
  static const artwork = 'assets/Icon/Icon lainnya.png';
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12,
    height: 1.5,
    color: muted,
  );
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(primary: green, onSurface: ink),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        textStyle: const TextStyle(
          fontFamily: 'NalaraInter',
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: green,
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        textStyle: const TextStyle(
          fontFamily: 'NalaraInter',
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: green),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class StudentSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const StudentSectionCard({
    super.key,
    required this.title,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xFFFEFDFC),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      border: Border.fromBorderSide(BorderSide(color: NalaraCardStyle.border)),
      boxShadow: [
        BoxShadow(
          color: NalaraCardStyle.shadow,
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: StudentDetailStyle.title),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class StudentSoftButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  const StudentSoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });
  @override
  Widget build(BuildContext context) => outlined
      ? OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: StudentDetailStyle.paleGreen,
          ),
          child: Text(label, textAlign: TextAlign.center),
        )
      : FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: StudentDetailStyle.paleGreen,
            foregroundColor: StudentDetailStyle.green,
          ),
          child: Text(label, textAlign: TextAlign.center),
        );
}
