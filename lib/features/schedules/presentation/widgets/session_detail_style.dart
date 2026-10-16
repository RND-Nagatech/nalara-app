import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import 'schedule_form_style.dart';

abstract final class SessionDetailStyle {
  static const cream = Color(0xFFFBF8F2),
      green = Color(0xFF155A49),
      ink = Color(0xFF10182B),
      muted = Color(0xFF7A7F89),
      sage = Color(0xFFEDF5EF),
      line = Color(0xFFEAEBED),
      red = Color(0xFFB83432),
      paleRed = Color(0xFFFFF2F0),
      amber = Color(0xFFFFF5DF);
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.5,
    color: muted,
  );

  static ThemeData theme(ThemeData base) =>
      ScheduleFormStyle.theme(base).copyWith(
        scaffoldBackgroundColor: cream,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: green,
            textStyle: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      );
}

class SessionSectionCard extends StatelessWidget {
  final String? title, description;
  final List<Widget> children;

  const SessionSectionCard({
    super.key,
    this.title,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: NalaraCardStyle.border),
      boxShadow: const [
        BoxShadow(
          color: NalaraCardStyle.shadow,
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) Text(title!, style: SessionDetailStyle.title),
        if (description != null) ...[
          const SizedBox(height: 5),
          Text(description!, style: SessionDetailStyle.body),
        ],
        if (title != null || description != null) const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

class SessionActionTile extends StatelessWidget {
  final String label;
  final String? description;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool destructive;

  const SessionActionTile({
    super.key,
    required this.label,
    this.description,
    this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? SessionDetailStyle.red
        : SessionDetailStyle.green;
    return Material(
      color: destructive ? SessionDetailStyle.paleRed : SessionDetailStyle.sage,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Opacity(
          opacity: onPressed == null ? .5 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 13),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: SessionDetailStyle.body.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          description!,
                          style: SessionDetailStyle.body.copyWith(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: color, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SessionStatusBadge extends StatelessWidget {
  final String label;
  final Color background, foreground;
  const SessionStatusBadge({
    super.key,
    required this.label,
    this.background = SessionDetailStyle.sage,
    this.foreground = SessionDetailStyle.green,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: SessionDetailStyle.body.copyWith(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
