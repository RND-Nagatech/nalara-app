import 'package:flutter/material.dart';
import '../../domain/entities/family.dart';
import 'families_style.dart';

/// A tappable family row inside the list's shared rounded surface.
class FamilyListRow extends StatelessWidget {
  final Family family;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final bool showDivider;

  const FamilyListRow({
    super.key,
    required this.family,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: borderRadius,
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: FamiliesStyle.sage,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: FamiliesStyle.green,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(family.parentName, style: FamiliesStyle.cardTitle),
                      const SizedBox(height: 3),
                      Text(family.parentPhone, style: FamiliesStyle.body),
                      const SizedBox(height: 3),
                      Text(
                        '${family.children.length} anak terdaftar',
                        style: const TextStyle(
                          fontFamily: 'NalaraInter',
                          fontSize: 12,
                          height: 1.35,
                          color: FamiliesStyle.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: FamiliesStyle.ink,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 78,
            endIndent: 16,
            color: FamiliesStyle.line,
          ),
      ],
    ),
  );
}
