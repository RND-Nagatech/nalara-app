import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/widgets/nalara_surface_card.dart';
import '../../../utils/color.dart';
import '../domain/teaching_guide.dart';
import 'teaching_guide_copy.dart';
import 'teaching_guide_cubit.dart';

class TeachingGuideCard extends StatelessWidget {
  final TeachingGuideCubit cubit;
  final ValueChanged<String> onOpen;
  final VoidCallback? onOpenGuide;
  final bool inHome;

  const TeachingGuideCard({
    super.key,
    required this.cubit,
    required this.onOpen,
    this.onOpenGuide,
    this.inHome = false,
  });

  static const _body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.5,
    color: NalaraColors.muted,
  );
  static const _title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: NalaraColors.ink,
  );

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TeachingGuideCubit, TeachingGuideState>(
    bloc: cubit,
    builder: (context, state) {
      final guide = state.value;
      final compact =
          inHome && guide != null && (guide.dismissed || guide.isComplete);
      return NalaraSurfaceCard(
        key: const ValueKey('teaching-guide-card'),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'LANGKAH AWAL NALARA',
              style: TextStyle(
                fontFamily: 'NalaraInter',
                fontSize: 10.5,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: NalaraColors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              guide?.isComplete == true
                  ? 'Persiapan mengajar selesai'
                  : compact
                  ? 'Lanjutkan persiapan mengajar'
                  : 'Siapkan kegiatan mengajar Anda',
              style: _title,
            ),
            if (guide != null) ...[
              const SizedBox(height: 8),
              Text(
                '${guide.completedCount} dari ${TeachingGuideStep.values.length} langkah selesai',
                key: const ValueKey('teaching-guide-progress-label'),
                style: _body,
              ),
              const SizedBox(height: 10),
              Semantics(
                label: 'Progres persiapan mengajar',
                value: '${guide.completedCount} dari 4 langkah',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    key: const ValueKey('teaching-guide-progress'),
                    value:
                        guide.completedCount / TeachingGuideStep.values.length,
                    minHeight: 6,
                    color: NalaraColors.green,
                    backgroundColor: const Color(0xFFE8F1EB),
                  ),
                ),
              ),
            ],
            if (state.busy) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 6),
              Text(
                state.saving
                    ? 'Menyimpan pilihan…'
                    : 'Memeriksa persiapan Anda…',
                style: _body,
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(state.error!, style: _body),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('teaching-guide-retry'),
                  onPressed: state.busy ? null : cubit.load,
                  child: const Text('Coba lagi'),
                ),
              ),
            ],
            if (guide != null && compact) ...[
              const SizedBox(height: 6),
              TextButton(
                key: const ValueKey('teaching-guide-open'),
                onPressed: state.busy ? null : onOpenGuide,
                child: Text(
                  guide.isComplete ? 'Lihat panduan' : 'Buka panduan',
                ),
              ),
            ] else if (guide != null) ...[
              const SizedBox(height: 14),
              const Text(
                'Ikuti langkah berikut sesuai kebutuhan Anda. Menu lainnya tetap dapat digunakan.',
                style: _body,
              ),
              const SizedBox(height: 8),
              for (final step in TeachingGuideStep.values)
                _GuideStepRow(
                  key: ValueKey('teaching-guide-step-${step.name}'),
                  step: step,
                  completed: guide.completed(step),
                  current: guide.nextStep == step,
                  onTap:
                      !state.busy &&
                          (guide.completed(step) || guide.nextStep == step)
                      ? () =>
                            onOpen(step.route(completed: guide.completed(step)))
                      : null,
                ),
              const SizedBox(height: 12),
              if (guide.nextStep case final step?)
                FilledButton(
                  key: const ValueKey('teaching-guide-next'),
                  onPressed: state.busy
                      ? null
                      : () => onOpen(step.route(completed: false)),
                  child: Text(
                    'Lanjut: ${step.title}',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                const Text(
                  'Anda siap mengajar. Saat sesi berlangsung, buka detail sesi untuk mencatat presensi dan membuat laporan belajar.',
                  style: _body,
                ),
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('teaching-guide-dismiss'),
                onPressed: state.busy
                    ? null
                    : () => cubit.setDismissed(!guide.dismissed),
                child: Text(
                  guide.dismissed
                      ? 'Tampilkan kembali di Beranda'
                      : inHome
                      ? 'Lewati sementara'
                      : 'Ringkas panduan di Beranda',
                ),
              ),
              const Text(
                'Progres tersimpan melalui data Anda. Panduan dapat dibuka kembali lewat Pusat Bantuan.',
                style: _body,
                textAlign: TextAlign.center,
              ),
            ],
            if (!inHome && guide != null) ...[
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 20),
              const Text(
                'Hubungkan orang tua · Opsional',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: NalaraColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                guide.parentConnected
                    ? 'Orang tua sudah terhubung ke siswa Anda.'
                    : 'Kelola keluarga siswa, lalu bagikan kode akses Orang Tua dari detail keluarga. Langkah ini tidak menghalangi persiapan lainnya.',
                style: _body,
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

class _GuideStepRow extends StatelessWidget {
  final TeachingGuideStep step;
  final bool completed, current;
  final VoidCallback? onTap;
  const _GuideStepRow({
    super.key,
    required this.step,
    required this.completed,
    required this.current,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${step.title}, ${completed
            ? 'selesai'
            : current
            ? 'langkah berikutnya'
            : 'belum selesai'}',
    button: onTap != null,
    child: Material(
      color: current ? const Color(0xFFF0F6F2) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? NalaraColors.green
                      : const Color(0xFFE8F1EB),
                ),
                child: completed
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : Text(
                        '${step.index + 1}',
                        style: const TextStyle(
                          color: NalaraColors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: NalaraColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      completed ? 'Sudah disiapkan' : step.description,
                      style: TeachingGuideCard._body,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
