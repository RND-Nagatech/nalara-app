import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/page_widgets.dart';
import '../../../utils/color.dart';
import '../../../utils/injector.dart';
import 'branding_logo_cubit.dart';

class BrandingLogoCard extends StatefulWidget {
  final bool hasStoredLogo;
  const BrandingLogoCard({super.key, this.hasStoredLogo = false});
  @override
  State<BrandingLogoCard> createState() => _BrandingLogoCardState();
}

class _BrandingLogoCardState extends State<BrandingLogoCard> {
  late final _cubit = getIt<BrandingLogoCubit>()..load();
  bool _confirming = false;
  bool get _current =>
      mounted &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      (GoRouter.maybeOf(context) == null ||
          GoRouter.of(context).state.uri.path == '/teacher/branding');
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _choose() async {
    if (!_current || _confirming) return;
    final saved = await _cubit.choose(isCurrent: () => _current);
    if (mounted && _current && saved) {
      successMessage(context, 'Logo laporan berhasil disimpan.');
    }
  }

  Future<void> _remove() async {
    if (!_current || _confirming || _cubit.state.busy) return;
    setState(() => _confirming = true);
    try {
      final confirmed = await confirmAction(
        context,
        'Hapus logo laporan? PDF yang diekspor berikutnya akan memakai identitas teks tanpa logo. Berkas PDF yang sudah dibagikan tidak berubah.',
      );
      if (!confirmed || !_current) return;
      final removed = await _cubit.remove();
      if (mounted && _current && removed) {
        successMessage(context, 'Logo laporan berhasil dihapus.');
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<BrandingLogoCubit, BrandingLogoState>(
    bloc: _cubit,
    builder: (context, state) {
      final logo = state.logo;
      final busy = state.busy || _confirming;
      final hasLogo =
          logo != null || (!state.initialized && widget.hasStoredLogo);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Logo laporan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: NalaraColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Identitas visual untuk laporan PDF Anda. Tersedia selama Trial aktif dan pada Tutor Pro.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: NalaraColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('branding-logo-preview'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: NalaraColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NalaraColors.line),
            ),
            child: Center(
              child: state.loading && logo == null
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )
                  : logo != null
                  ? Image.memory(
                      Uint8List.fromList(logo.bytes),
                      key: ValueKey('branding-logo-${logo.version}'),
                      width: 140,
                      height: 100,
                      fit: BoxFit.contain,
                      semanticLabel: 'Logo laporan tersimpan',
                      errorBuilder: (_, _, _) => const Text(
                        'Pratinjau gambar tidak dapat ditampilkan. Unggah logo kembali.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        state.initialized
                            ? 'Belum ada logo'
                            : 'Pratinjau logo belum tersedia',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: NalaraColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const ValueKey('branding-logo-upload'),
                onPressed: busy ? null : _choose,
                child: Text(
                  state.saving
                      ? 'Memproses logo…'
                      : hasLogo
                      ? 'Ganti logo'
                      : 'Pilih logo',
                ),
              ),
              if (hasLogo)
                TextButton(
                  key: const ValueKey('branding-logo-remove'),
                  onPressed: busy ? null : _remove,
                  style: TextButton.styleFrom(
                    foregroundColor: NalaraColors.danger,
                  ),
                  child: const Text('Hapus logo'),
                ),
            ],
          ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                state.error!,
                key: const ValueKey('branding-logo-error'),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: NalaraColors.danger,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('branding-logo-retry'),
              onPressed: busy ? null : _cubit.load,
              child: const Text('Muat ulang logo'),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'PNG atau JPEG, maksimal 2 MB dan 4 megapiksel. PNG berlatar transparan dianjurkan. Logo langsung tersimpan terpisah dari pengaturan teks di bawah; hanya PDF yang diekspor setelahnya yang mengikuti perubahan.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.6,
              color: NalaraColors.muted,
            ),
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 22),
        ],
      );
    },
  );
}
