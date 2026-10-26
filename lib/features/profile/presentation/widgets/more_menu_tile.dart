import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import 'more_style.dart';

// Presentation-only navigation configuration, not a backend/domain entity.
class MoreMenuItem {
  final String id, title, description, route;
  final IconData icon;
  final Color foreground, background;
  const MoreMenuItem({
    required this.id,
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    this.foreground = MoreStyle.green,
    this.background = MoreStyle.sage,
  });
}

class MoreMenuTile extends StatelessWidget {
  final MoreMenuItem item;
  final VoidCallback onTap;
  final Widget? trailing;
  const MoreMenuTile({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.fromBorderSide(
          BorderSide(color: NalaraCardStyle.border),
        ),
        boxShadow: [
          BoxShadow(
            color: NalaraCardStyle.shadow,
            blurRadius: 16,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(item.background, Colors.white, .4)!,
                          item.background,
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0B536553),
                          blurRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      item.icon,
                      color: item.foreground,
                      size: 29,
                      shadows: [
                        Shadow(
                          color: item.foreground.withValues(alpha: .15),
                          offset: const Offset(0, 1.5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: MoreStyle.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 11.5,
                          height: 1.4,
                          color: MoreStyle.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
                const ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 23,
                    color: MoreStyle.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
