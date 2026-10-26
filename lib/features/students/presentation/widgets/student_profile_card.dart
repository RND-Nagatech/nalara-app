import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../../shared/widgets/nalara_avatar.dart';
import '../../domain/entities/student.dart';
import 'student_detail_style.dart';

class StudentProfileCard extends StatelessWidget {
  final Student student;
  final VoidCallback? onEdit;
  final VoidCallback? onEditAvatar;
  final bool showInternalNotes;
  const StudentProfileCard({
    super.key,
    required this.student,
    required this.onEdit,
    this.onEditAvatar,
    this.showInternalNotes = true,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: NalaraCardStyle.decoration(radius: 16),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 340 ||
                  MediaQuery.textScalerOf(context).scale(12) > 17 ||
                  student.grade.length > 28 ||
                  (showInternalNotes && student.notes.length > 40);
              final artwork = Image.asset(
                StudentDetailStyle.artwork,
                key: const ValueKey('student-detail-artwork'),
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              );
              return Stack(
                children: [
                  if (!stacked)
                    Positioned(
                      right: -10,
                      bottom: 0,
                      width: math.min(200, constraints.maxWidth * .5),
                      child: IgnorePointer(child: artwork),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (student.avatarId != null ||
                                onEditAvatar != null) ...[
                              NalaraAvatar(
                                name: student.name,
                                avatarId: student.avatarId,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                student.name,
                                style: const TextStyle(
                                  fontFamily: 'NalaraInter',
                                  fontSize: 20,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                  color: StudentDetailStyle.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: stacked ? double.infinity : 260,
                            ),
                            child: Column(
                              children: [
                                _fact(
                                  'Kelas / tingkat',
                                  Text(
                                    student.grade.isEmpty
                                        ? 'Belum diisi'
                                        : student.grade,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _fact(
                                  'Status',
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: student.status == 'active'
                                            ? const Color(0xFFE2F0E1)
                                            : const Color(0xFFF0EDE7),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        child: Text(
                                          statusLabel(student.status),
                                          key: const ValueKey('student-status'),
                                          style: TextStyle(
                                            color: student.status == 'active'
                                                ? StudentDetailStyle.green
                                                : StudentDetailStyle.muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (showInternalNotes) ...[
                                  const SizedBox(height: 8),
                                  _fact(
                                    'Catatan internal Guru',
                                    Text(
                                      student.notes.isEmpty
                                          ? 'Belum ada catatan.'
                                          : student.notes,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (stacked)
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(width: 170, child: artwork),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (onEditAvatar != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: OutlinedButton.icon(
                key: const ValueKey('student-edit-avatar'),
                onPressed: onEditAvatar,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit foto profil'),
              ),
            ),
          if (onEdit != null) ...[
            const Divider(height: 1, color: Color(0xFFF0EDE7)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: StudentSoftButton(
                key: const ValueKey('student-edit-profile'),
                label: 'Edit profil',
                onPressed: onEdit,
                outlined: true,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _fact(String label, Widget value) => DefaultTextStyle(
    style: const TextStyle(
      fontFamily: 'NalaraInter',
      fontSize: 11,
      height: 1.4,
      color: StudentDetailStyle.ink,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 102,
          child: Text(
            label,
            style: const TextStyle(color: StudentDetailStyle.muted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: value),
      ],
    ),
  );
}
