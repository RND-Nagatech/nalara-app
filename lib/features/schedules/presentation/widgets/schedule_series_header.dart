import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_page_header.dart';
import 'session_detail_style.dart';

class ScheduleSeriesHeader extends StatelessWidget {
  static const artwork = 'assets/Icon/Icon les hari ini.png';
  final VoidCallback? onBack;
  const ScheduleSeriesHeader({super.key, required this.onBack});
  @override
  Widget build(BuildContext context) => NalaraPageHeader(
    title: 'Seri jadwal',
    backKey: const ValueKey('series-back'),
    onBack: onBack,
    backEnabled: onBack != null,
  );
}

class ScheduleSeriesIntro extends StatelessWidget {
  static const artwork = ScheduleSeriesHeader.artwork;
  const ScheduleSeriesIntro({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 350 ||
          MediaQuery.textScalerOf(context).scale(14) > 16;
      final width = math.min(210.0, constraints.maxWidth * .5);
      final illustration = Image.asset(
        artwork,
        key: const ValueKey('series-header-artwork'),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );

      const description = Text(
        'Informasi jadwal berulang untuk pertemuan dengan siswa.',
        style: SessionDetailStyle.body,
      );
      if (stacked) {
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              description,
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(width: 200, child: illustration),
              ),
            ],
          ),
        );
      }
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(174, width / 1.17 + 22),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 24,
              child: Container(
                width: width,
                height: width * .65,
                decoration: BoxDecoration(
                  color: SessionDetailStyle.sage,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(width),
                    bottomRight: Radius.circular(width * .4),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 14,
              width: width,
              child: IgnorePointer(child: illustration),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - width - 10,
                    ),
                    child: description,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
