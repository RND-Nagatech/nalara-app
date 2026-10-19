import 'package:flutter/material.dart';
import 'home_style.dart';

class HomeEmptySchedule extends StatelessWidget {
  final VoidCallback onCreate;
  final bool showAction;
  final String? description;
  const HomeEmptySchedule({
    super.key,
    required this.onCreate,
    this.showAction = true,
    this.description,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: Image.asset(
              HomeStyle.emptyArtwork,
              key: const ValueKey('home-empty-artwork'),
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Belum ada sesi hari ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: HomeStyle.ink,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description ??
                'Mulai buat jadwal les untuk mengatur kegiatan mengajar Anda.',
            textAlign: TextAlign.center,
            style: HomeStyle.supporting,
          ),
          if (showAction) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              key: const ValueKey('home-create-schedule'),
              onPressed: onCreate,
              style: OutlinedButton.styleFrom(
                foregroundColor: HomeStyle.green,
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: HomeStyle.green),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 48),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: HomeStyle.green,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(Icons.add, color: Colors.white, size: 19),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Buat jadwal les',
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
          ],
        ],
      ),
    ),
  );
}
