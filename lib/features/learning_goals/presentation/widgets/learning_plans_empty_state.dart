import 'package:flutter/material.dart';
import 'learning_plans_style.dart';

class LearningPlansEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final bool showAction;
  final String? description;
  final String title;
  const LearningPlansEmptyState({
    super.key,
    required this.onAdd,
    this.showAction = true,
    this.description,
    this.title = 'Belum ada rencana belajar.',
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 28, 22, 36),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Image.asset(
            LearningPlansStyle.emptyArtwork,
            key: const ValueKey('target-empty-artwork'),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: LearningPlansStyle.ink,
          ),
        ),
        const SizedBox(height: 9),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            description ??
                'Mulai dengan menentukan periode dan target belajar untuk siswa.',
            textAlign: TextAlign.center,
            style: LearningPlansStyle.body,
          ),
        ),
        if (showAction) ...[
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: FilledButton(
              key: const ValueKey('target-add-empty'),
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: LearningPlansStyle.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(192, 46),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 12,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle, size: 23),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Tambah sekarang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
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
