import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import 'more_style.dart';

abstract final class SettingsStyle {
  static const cream = MoreStyle.cream,
      green = MoreStyle.green,
      ink = MoreStyle.ink,
      muted = Color(0xFF626D66),
      sage = MoreStyle.sage,
      line = Color(0xFFE7EAE4);
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.6,
    color: muted,
  );
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(primary: green, onSurface: ink),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        backgroundColor: green,
        foregroundColor: Colors.white,
        textStyle: body.copyWith(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class SettingsSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: NalaraCardStyle.border),
      boxShadow: const [
        BoxShadow(
          color: NalaraCardStyle.shadow,
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(21),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: SettingsStyle.title),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class SettingsInfoRow extends StatelessWidget {
  final String label, value;
  const SettingsInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 320 ||
          MediaQuery.textScalerOf(context).scale(13) > 16;
      final labelText = Text(label, style: SettingsStyle.body);
      final valueText = Text(
        value,
        textAlign: stacked ? TextAlign.left : TextAlign.right,
        style: SettingsStyle.body.copyWith(
          color: SettingsStyle.ink,
          fontWeight: FontWeight.w600,
        ),
      );
      return stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 4), valueText],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: labelText),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: valueText),
              ],
            );
    },
  );
}

class SettingsDocumentLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SettingsDocumentLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: SettingsStyle.body.copyWith(
                  color: SettingsStyle.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const ExcludeSemantics(
              child: Icon(
                Icons.chevron_right_rounded,
                color: SettingsStyle.green,
                size: 21,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
