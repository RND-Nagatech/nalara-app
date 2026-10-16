import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../auth/domain/entities/teacher.dart';
import 'profile_style.dart';

class ProfileAccountCard extends StatelessWidget {
  final Teacher teacher;

  const ProfileAccountCard({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('profile-account-info'),
    decoration: BoxDecoration(
      color: ProfileStyle.paper,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: NalaraCardStyle.border),
      boxShadow: const [
        BoxShadow(
          color: NalaraCardStyle.shadow,
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: teacher.email.isEmpty ? 'Belum tersedia' : teacher.email,
          ),
          const Divider(height: 1, indent: 56, color: ProfileStyle.line),
          _AccountRow(
            icon: Icons.phone_outlined,
            label: 'Nomor HP',
            value: teacher.phone?.trim().isNotEmpty == true
                ? teacher.phone!
                : 'Belum ditambahkan',
          ),
          const Divider(height: 1, indent: 56, color: ProfileStyle.line),
          _AccountRow(
            icon: Icons.schedule_rounded,
            label: 'Zona waktu',
            value: teacher.timezone.isEmpty
                ? 'Belum tersedia'
                : teacher.timezone,
          ),
        ],
      ),
    ),
  );
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ProfileStyle.sage,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 21, color: ProfileStyle.green),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ProfileStyle.body.copyWith(fontSize: 12)),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: ProfileStyle.body.copyWith(
                  color: ProfileStyle.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
