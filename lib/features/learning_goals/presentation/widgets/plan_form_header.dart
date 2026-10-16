import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'plan_form_style.dart';

class PlanFormHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const PlanFormHeader({super.key, required this.title, required this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('plan-form-back'),
          tooltip: 'Kembali',
          onPressed: onBack,
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: PlanFormStyle.green,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 25),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(title, style: PlanFormStyle.label.copyWith(fontSize: 17)),
        ),
      ],
    ),
  );
}

class PlanFormHero extends StatelessWidget {
  final bool continuing;
  const PlanFormHero({super.key, this.continuing = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 6, 6, 20),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(14) > 19;
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              continuing
                  ? 'Teruskan\ntarget belajar'
                  : 'Buat rencana\n& target',
              style: PlanFormStyle.label.copyWith(
                fontSize: 26,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Atur rencana belajar dan target untuk perkembangan siswa.',
              style: PlanFormStyle.supporting,
            ),
          ],
        );
        final artwork = Image.asset(
          PlanFormStyle.artwork,
          key: const ValueKey('plan-form-artwork'),
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              intro,
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(width: 240, child: artwork),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: intro),
            const SizedBox(width: 8),
            SizedBox(
              width: math.min(240, constraints.maxWidth * .48),
              child: artwork,
            ),
          ],
        );
      },
    ),
  );
}
