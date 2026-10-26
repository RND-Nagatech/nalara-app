import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../shared/widgets/feedback_notice.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../shared/widgets/nalara_dialog.dart';
import '../../../../utils/color.dart';
import '../../domain/entities/referral_invitation.dart';

Future<void> showReferralCode(
  BuildContext context,
  ReferralInvitation invitation, {
  required String title,
}) => showDialog<void>(
  context: context,
  barrierColor: NalaraColors.scrim,
  builder: (context) => NalaraDialog(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E292D),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE7EFE5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: SelectableText(
            invitation.token!,
            style: const TextStyle(
              fontFamily: 'NalaraInter',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 1.3,
              color: Color(0xFF155A49),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${invitation.expiresAt == null ? 'Kode dapat digunakan kembali tanpa batas waktu sampai Guru mengganti atau mencabutnya.' : 'Berlaku sampai ${DateTimeUtils.date(invitation.expiresAt!)}.'} Simpan atau salin sekarang; kode hanya ditampilkan saat dibuat.',
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF7B7F80),
          ),
        ),
        const SizedBox(height: 16),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          spacing: 8,
          overflowSpacing: 8,
          overflowAlignment: OverflowBarAlignment.end,
          children: [
            TextButton(
              onPressed: () async {
                try {
                  await Clipboard.setData(
                    ClipboardData(text: invitation.token!),
                  );
                  if (context.mounted) {
                    await showNalaraNotice(
                      context,
                      'Kode berhasil disalin.',
                      title: 'Kode disalin',
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    await showNalaraNotice(
                      context,
                      'Kode belum dapat disalin. Salin teks kode secara manual.',
                    );
                  }
                }
              },
              child: const Text('Salin kode'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ],
    ),
  ),
);

class ReferralInvitationTile extends StatelessWidget {
  final ReferralInvitation invitation;
  final VoidCallback onRevoke;
  const ReferralInvitationTile({
    super.key,
    required this.invitation,
    required this.onRevoke,
  });
  @override
  Widget build(BuildContext context) {
    final lastUsed = invitation.lastUsedAt ?? invitation.redeemedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NalaraSurfaceCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE7EFE5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.key_rounded,
                color: Color(0xFF155A49),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invitation.expiresAt == null
                        ? 'Berlaku tanpa batas waktu'
                        : 'Berlaku sampai ${DateTimeUtils.date(invitation.expiresAt!)}',
                    style: const TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E292D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invitation.revokedAt != null
                        ? 'Dicabut'
                        : lastUsed != null
                        ? 'Aktif · Terakhir digunakan ${DateTimeUtils.date(lastUsed)}'
                        : 'Aktif · Belum digunakan',
                    style: const TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 12.5,
                      color: Color(0xFF7B7F80),
                    ),
                  ),
                ],
              ),
            ),
            if (invitation.revokedAt == null)
              TextButton(onPressed: onRevoke, child: const Text('Cabut kode')),
          ],
        ),
      ),
    );
  }
}
