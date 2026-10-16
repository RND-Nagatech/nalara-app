import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../../shared/widgets/feedback_notice.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../domain/entities/referral_invitation.dart';

Future<void> showReferralCode(
  BuildContext context,
  ReferralInvitation invitation, {
  required String title,
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: .16),
  builder: (context) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
    child: NalaraSurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      radius: 20,
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
            'Berlaku sampai ${DateTimeUtils.date(invitation.expiresAt)}. Hanya dapat digunakan sekali. Simpan atau salin sekarang; kode tidak ditampilkan lagi.',
            style: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF7B7F80),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ],
      ),
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
    final expired = invitation.expiresAt.isBefore(DateTime.now());
    final used = invitation.redeemedAt != null;
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
                    'Berlaku sampai ${DateTimeUtils.date(invitation.expiresAt)}',
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
                        : used
                        ? 'Sudah digunakan'
                        : expired
                        ? 'Kedaluwarsa'
                        : 'Belum digunakan',
                    style: const TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 12.5,
                      color: Color(0xFF7B7F80),
                    ),
                  ),
                ],
              ),
            ),
            if (invitation.revokedAt == null && !used && !expired)
              TextButton(onPressed: onRevoke, child: const Text('Cabut kode')),
          ],
        ),
      ),
    );
  }
}
