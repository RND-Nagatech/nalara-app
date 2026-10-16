import 'package:flutter/material.dart';
import 'agenda_style.dart';

class SchedulePrerequisites extends StatelessWidget {
  final VoidCallback onAddStudent;
  final VoidCallback onAddSubject;

  const SchedulePrerequisites({
    super.key,
    required this.onAddStudent,
    required this.onAddSubject,
  });

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const ValueKey('schedule-prerequisites-scroll'),
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Image.asset(
                      AgendaStyle.emptyArtwork,
                      key: const ValueKey('schedule-prerequisites-artwork'),
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tambahkan siswa aktif\ndan bidang belajar terlebih dahulu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 20,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: AgendaStyle.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Setelah siswa dan bidang belajar tersedia, Anda dapat membuat jadwal les.',
                    textAlign: TextAlign.center,
                    style: AgendaStyle.body,
                  ),
                  const SizedBox(height: 28),
                  _PrerequisiteAction(
                    key: const ValueKey('schedule-add-student'),
                    label: 'Tambah siswa',
                    onPressed: onAddStudent,
                  ),
                  const SizedBox(height: 14),
                  _PrerequisiteAction(
                    key: const ValueKey('schedule-add-subject'),
                    label: 'Tambah bidang belajar',
                    onPressed: onAddSubject,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _PrerequisiteAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrerequisiteAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE8F0E7),
          foregroundColor: AgendaStyle.green,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 24),
          ],
        ),
      ),
    ),
  );
}
