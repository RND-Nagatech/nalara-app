import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_avatar.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../utils/color.dart';
import '../../../students/domain/entities/student.dart';

class ParentChildSwitcher extends StatelessWidget {
  final List<Student> children;
  final String? selectedChildId;
  final ValueChanged<String?> onChanged;

  const ParentChildSwitcher({
    super.key,
    required this.children,
    required this.selectedChildId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: NalaraColors.line),
    );
    return NalaraDropdown<String>(
      key: const ValueKey('parent-child-switcher'),
      value: selectedChildId ?? '',
      menuTitle: 'Pilih anak',
      searchHint: 'Cari nama atau kelas anak',
      decoration: InputDecoration(
        filled: true,
        fillColor: NalaraColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: NalaraColors.green, width: 1.4),
        ),
      ),
      options: [
        NalaraDropdownOption(
          value: '',
          label: 'Semua anak',
          subtitle: '${children.length} anak terhubung',
          leading: _FamilyAvatars(children: children),
        ),
        for (final child in children)
          NalaraDropdownOption(
            value: child.id,
            label: child.name,
            subtitle: child.grade,
            leading: SizedBox(
              width: 54,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: NalaraAvatar(
                  name: child.name,
                  avatarId: child.avatarId,
                  size: 40,
                ),
              ),
            ),
          ),
      ],
      selectedBuilder: (context, option) => Row(
        children: [
          if (option?.leading != null) ...[
            option!.leading!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tampilkan anak',
                  style: TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 11,
                    height: 1.4,
                    color: NalaraColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option?.label ?? 'Pilihan tersimpan',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: NalaraColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      onChanged: (id) => onChanged(id == '' ? null : id),
    );
  }
}

class _FamilyAvatars extends StatelessWidget {
  final List<Student> children;
  const _FamilyAvatars({required this.children});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 54,
    height: 40,
    child: Stack(
      children: [
        for (var index = 0; index < children.length && index < 2; index++)
          PositionedDirectional(
            start: index * 18,
            top: index == 0 ? 0 : 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: NalaraColors.surface,
              ),
              child: NalaraAvatar(
                name: children[index].name,
                avatarId: children[index].avatarId,
                size: 32,
              ),
            ),
          ),
      ],
    ),
  );
}
