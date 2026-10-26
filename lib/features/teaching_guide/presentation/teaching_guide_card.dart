import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/widgets/nalara_surface_card.dart';
import '../../../utils/color.dart';
import '../domain/teaching_guide.dart';
import 'teaching_guide_copy.dart';
import 'teaching_guide_cubit.dart';
import 'teaching_tutorial_scope.dart';

/// Permanent checklist, shown only on the guide page in Lainnya.
class TeachingGuideCard extends StatelessWidget {
  final TeachingGuideCubit cubit;
  final ValueChanged<String> onOpen;
  final ValueChanged<TeachingGuideStep>? onStart;
  const TeachingGuideCard({
    super.key,
    required this.cubit,
    required this.onOpen,
    this.onStart,
  });

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TeachingGuideCubit, TeachingGuideState>(
    bloc: cubit,
    builder: (context, state) {
      final guide = state.value;
      return NalaraSurfaceCard(
        key: const ValueKey('teaching-guide-card'),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PANDUAN MENGAJAR',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                color: NalaraColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    guide?.isComplete == true
                        ? 'Persiapan mengajar selesai'
                        : 'Mulai dengan langkah kecil',
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (guide != null) GuideCountBadge(count: guide.remainingCount),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Ikuti petunjuk langsung di halaman yang Anda gunakan. Panduan yang dilewati dapat dilanjutkan kapan saja dari Lainnya.',
              style: TextStyle(height: 1.5, color: NalaraColors.muted),
            ),
            if (guide != null) ...[
              const SizedBox(height: 16),
              Text(
                '${guide.completedCount} dari 4 panduan selesai',
                key: const ValueKey('teaching-guide-progress-label'),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                key: const ValueKey('teaching-guide-progress'),
                value: guide.completedCount / 4,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
            if (state.busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            if (state.error != null) ...[
              const SizedBox(height: 14),
              Text(
                state.error!,
                style: const TextStyle(color: NalaraColors.danger),
              ),
              TextButton(
                onPressed: state.busy ? null : cubit.load,
                child: const Text('Coba lagi'),
              ),
            ],
            if (guide != null) ...[
              const SizedBox(height: 16),
              for (final step in TeachingGuideStep.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    key: ValueKey('teaching-guide-step-${step.name}'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: const Color(0xFFF0F6F2),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: guide.completed(step)
                          ? NalaraColors.green
                          : const Color(0xFFE1EBE5),
                      child: guide.completed(step)
                          ? const Icon(
                              Icons.check_rounded,
                              size: 19,
                              color: Colors.white,
                            )
                          : Text(
                              '${step.index + 1}',
                              style: const TextStyle(color: NalaraColors.green),
                            ),
                    ),
                    title: Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      guide.completed(step)
                          ? 'Selesai · buka menu'
                          : guide.canStart(step)
                          ? 'Belum selesai · mulai panduan'
                          : 'Siapkan bidang belajar dan siswa terlebih dahulu',
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                    trailing: guide.completed(step)
                        ? const Icon(Icons.chevron_right_rounded)
                        : const GuideCountBadge(count: 1),
                    onTap: state.busy || !guide.canStart(step)
                        ? null
                        : () {
                            if (guide.completed(step)) {
                              onOpen(step.route(completed: true));
                            } else {
                              onStart?.call(step);
                            }
                          },
                  ),
                ),
              if (guide.nextStep case final step?)
                FilledButton(
                  key: const ValueKey('teaching-guide-next'),
                  onPressed: state.busy ? null : () => onStart?.call(step),
                  child: const Text('Lanjutkan panduan'),
                ),
              const SizedBox(height: 18),
              Text(
                guide.parentConnected
                    ? 'Orang tua sudah terhubung.'
                    : 'Hubungkan orang tua · Opsional',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kelola keluarga siswa, kemudian bagikan kode akses kepada orang tua yang berhak.',
                style: TextStyle(color: NalaraColors.muted, height: 1.5),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                key: const ValueKey('teaching-guide-families'),
                onPressed: state.busy
                    ? null
                    : () => onOpen('/teacher/families'),
                child: const Text('Buka Orang Tua & Keluarga'),
              ),
            ],
          ],
        ),
      );
    },
  );
}
