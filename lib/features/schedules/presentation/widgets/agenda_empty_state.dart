import 'package:flutter/material.dart';
import '../../../teaching_guide/presentation/teaching_tutorial_scope.dart';
import '../../domain/entities/schedule_period.dart';
import 'agenda_style.dart';

class AgendaEmptyState extends StatelessWidget {
  final SchedulePeriod period;
  final VoidCallback onAdd;
  final bool attendance;
  final bool showAction;
  final String? description;
  const AgendaEmptyState({
    super.key,
    required this.period,
    required this.onAdd,
    this.attendance = false,
    this.showAction = true,
    this.description,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 26, 22, 34),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Image.asset(
            AgendaStyle.emptyArtwork,
            key: ValueKey(
              '${attendance ? 'attendance' : 'agenda'}-empty-artwork-${period.name}',
            ),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          AgendaStyle.emptyTitle(period),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AgendaStyle.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description ??
              (attendance
                  ? 'Buat jadwal terlebih dahulu. Kehadiran siswa dicatat melalui detail sesi.'
                  : 'Mulai buat jadwal les untuk mengatur kegiatan mengajar Anda.'),
          textAlign: TextAlign.center,
          style: AgendaStyle.body,
        ),
        if (showAction) ...[
          const SizedBox(height: 18),
          TutorialTarget(
            id: 'add-schedule',
            child: FilledButton(
              key: ValueKey(
                '${attendance ? 'attendance' : 'agenda'}-add-empty-${period.name}',
              ),
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AgendaStyle.green,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 46),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!attendance) ...[
                    const Icon(Icons.add_circle, size: 23),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      attendance ? 'Buat jadwal' : 'Tambah sekarang',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
