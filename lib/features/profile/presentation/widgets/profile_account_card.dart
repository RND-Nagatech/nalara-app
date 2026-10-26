import 'package:flutter/material.dart';
import '../../../../shared/domain/app_timezones.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../../auth/domain/entities/teacher.dart';
import 'profile_style.dart';

class ProfileAccountCard extends StatelessWidget {
  final Teacher teacher;
  final Widget? phoneEditor;

  const ProfileAccountCard({
    super.key,
    required this.teacher,
    this.phoneEditor,
  });

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AccountRow(
            label: 'Email',
            value: teacher.email.isEmpty ? 'Belum tersedia' : teacher.email,
          ),
          const Divider(height: 1, color: ProfileStyle.line),
          phoneEditor ??
              _AccountRow(
                label: 'Nomor HP',
                value: teacher.phone?.trim().isNotEmpty == true
                    ? teacher.phone!
                    : 'Belum ditambahkan',
              ),
          const Divider(height: 1, color: ProfileStyle.line),
          _AccountRow(
            label: 'Zona waktu',
            value: teacher.timezone.isEmpty
                ? 'Belum tersedia'
                : AppTimezones.label(teacher.timezone),
          ),
        ],
      ),
    ),
  );
}

class _AccountRow extends StatelessWidget {
  final String label, value;

  const _AccountRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
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
  );
}
