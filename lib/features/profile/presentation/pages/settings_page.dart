import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_style.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: SettingsStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: SettingsStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  NalaraHeader(child: _navigation(context)),
                  Expanded(child: _content(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _navigation(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('settings-back'),
          tooltip: 'Kembali',
          onPressed: () => finishForm(context, '/teacher/more'),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: SettingsStyle.green,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Pengaturan',
            style: TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 17,
              height: 1.4,
              color: SettingsStyle.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _content(BuildContext context) => SingleChildScrollView(
    key: const PageStorageKey('settings-scroll'),
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsHeader(),
        const SettingsSectionCard(
          key: ValueKey('settings-preferences'),
          title: 'Preferensi aplikasi',
          children: [
            SettingsInfoRow(
              key: ValueKey('settings-language'),
              label: 'Bahasa',
              value: 'Bahasa Indonesia',
            ),
            Divider(height: 30, color: SettingsStyle.line),
            SettingsInfoRow(
              key: ValueKey('settings-time'),
              label: 'Tampilan waktu',
              value: 'WIB · Asia/Jakarta',
            ),
            SizedBox(height: 14),
            Text(
              'Acuan waktu default aplikasi. Jadwal mengikuti zona waktu yang dipilih saat dibuat.',
              style: SettingsStyle.body,
            ),
          ],
        ),
        SettingsSectionCard(
          title: 'Notifikasi',
          children: [
            const Text(
              'Sesuaikan pengingat dan pembaruan yang diterima akun Guru.',
              style: SettingsStyle.body,
            ),
            TextButton(
              onPressed: () =>
                  context.push('/teacher/notification-preferences'),
              child: const Text('Atur preferensi notifikasi · Pro'),
            ),
          ],
        ),
        SettingsSectionCard(
          key: const ValueKey('settings-privacy'),
          title: 'Privasi belajar',
          children: [
            const Text(
              'Catatan internal hanya untuk Guru. Pilih visibilitas saat menyimpan progress atau laporan.',
              style: SettingsStyle.body,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: SettingsStyle.line),
            SettingsDocumentLink(
              key: const ValueKey('settings-open-privacy'),
              label: 'Kebijakan privasi',
              onTap: () => context.push('/legal/kebijakan-privasi'),
            ),
            const Divider(height: 1, color: SettingsStyle.line),
            SettingsDocumentLink(
              key: const ValueKey('settings-open-terms'),
              label: 'Syarat & ketentuan',
              onTap: () => context.push('/legal/syarat-dan-ketentuan'),
            ),
          ],
        ),
        Padding(
          key: const ValueKey('settings-help'),
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bantuan akun & keamanan', style: SettingsStyle.title),
              const SizedBox(height: 6),
              const Text(
                'Temukan panduan penggunaan dan jawaban atas pertanyaan Anda.',
                style: SettingsStyle.body,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('settings-open-help'),
                  onPressed: () => context.push('/teacher/help'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    foregroundColor: SettingsStyle.ink,
                    overlayColor: Colors.transparent,
                    textStyle: SettingsStyle.body.copyWith(
                      color: SettingsStyle.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Buka Pusat Bantuan'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
