import 'package:flutter/material.dart';
import '../../utils/color.dart';
import '../../utils/constants.dart';

/// One rendering path for selected server characters and the initials fallback.
class NalaraAvatar extends StatelessWidget {
  final String name;
  final String? avatarId;
  final double size;
  final Color backgroundColor, foregroundColor;
  final int maxInitials;
  const NalaraAvatar({
    super.key,
    required this.name,
    this.avatarId,
    this.size = 52,
    this.backgroundColor = NalaraColors.lightGreen,
    this.foregroundColor = NalaraColors.green,
    this.maxInitials = 2,
  });

  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? ''
        : '${words.first.characters.first}${maxInitials > 1 && words.length > 1 ? words.last.characters.first : ''}'
              .toUpperCase();
    Widget fallback() => Center(
      child: initials.isEmpty
          ? Icon(
              Icons.person_outline_rounded,
              color: foregroundColor,
              size: size * .48,
            )
          : Padding(
              padding: EdgeInsets.all(size * .12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: 'NalaraInter',
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: size * .37,
                  ),
                ),
              ),
            ),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: backgroundColor,
          child: avatarId == null || avatarId!.isEmpty
              ? fallback()
              : Image.network(
                  '${ApiConstants.baseUrl.replaceFirst(RegExp(r'/+$'), '')}/avatars/${Uri.encodeComponent(avatarId!)}/image',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => fallback(),
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : fallback(),
                ),
        ),
      ),
    );
  }
}
