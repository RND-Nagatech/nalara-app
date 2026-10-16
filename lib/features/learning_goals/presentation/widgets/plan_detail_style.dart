import 'package:flutter/material.dart';

abstract final class PlanDetailStyle {
  static const cream = Color(0xFFFBF9F4),
      green = Color(0xFF155A49),
      ink = Color(0xFF122A2D),
      navy = Color(0xFF101B33),
      muted = Color(0xFF747D8A),
      paleGreen = Color(0xFFEAF3EC),
      track = Color(0xFFDDEDE2);
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.5,
    color: muted,
  );
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: navy,
  );
  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(primary: green, onSurface: ink),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: body.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class PlanDetailCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PlanDetailCard({super.key, required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7E5DC)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x076D6B5A),
          blurRadius: 18,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(17), child: child),
      ),
    ),
  );
}

class PlanProgressTrack extends StatelessWidget {
  final int progress;
  const PlanProgressTrack({super.key, required this.progress});
  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
    value: progress / 100,
    minHeight: 8,
    borderRadius: BorderRadius.circular(8),
    color: PlanDetailStyle.green,
    backgroundColor: PlanDetailStyle.track,
    semanticsLabel: 'Progres',
    semanticsValue: '$progress%',
  );
}
