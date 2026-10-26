import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/widgets/nalara_dropdown.dart';
import '../../../utils/color.dart';
import '../domain/load_activity_options.dart';
import 'activity_recipients_cubit.dart';

class ActivityRecipientsFields extends StatelessWidget {
  final ActivityRecipientsCubit cubit;
  final ActivityOptions options;
  final bool enabled;
  final VoidCallback? manageGroups;
  final String? lockedStudentName;
  const ActivityRecipientsFields({
    super.key,
    required this.cubit,
    required this.options,
    this.enabled = true,
    this.manageGroups,
    this.lockedStudentName,
  });

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ActivityRecipientsCubit, ActivityRecipientsState>(
    bloc: cubit,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!cubit.locked) ...[
          NalaraDropdown<String>(
            key: const ValueKey('activity-student-group'),
            value: state.groupId ?? '',
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'Grup siswa (opsional)',
            ),
            menuTitle: 'Pilih grup siswa',
            searchHint: 'Cari grup...',
            options: [
              const NalaraDropdownOption(
                value: '',
                label: 'Pilih siswa secara manual',
              ),
              for (final group in options.groups)
                NalaraDropdownOption(
                  value: group.id,
                  label: '${group.name} · ${group.studentIds.length} siswa',
                ),
              if (state.groupId != null &&
                  !options.groups.any((g) => g.id == state.groupId))
                NalaraDropdownOption(
                  value: state.groupId!,
                  label: 'Grup tidak lagi tersedia',
                ),
            ],
            onChanged: cubit.selectGroup,
          ),
          const SizedBox(height: 8),
          Text(
            state.notice ??
                'Memilih grup mengganti pilihan dengan anggota aktif. Anda bisa menambah atau mengurangi siswa setelahnya.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: NalaraColors.muted,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: enabled ? manageGroups : null,
              child: Text(
                options.groups.isEmpty
                    ? 'Buat grup siswa'
                    : 'Kelola grup siswa',
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        NalaraMultiDropdown<String>(
          key: const ValueKey('activity-students'),
          selectedValues: state.studentIds,
          enabled: enabled && !cubit.locked,
          decoration: const InputDecoration(labelText: 'Siswa'),
          menuTitle: 'Pilih siswa',
          searchHint: 'Cari siswa...',
          hint: 'Pilih satu atau beberapa siswa',
          validator: cubit.validate,
          options: [
            for (final student in options.students)
              NalaraDropdownOption(value: student.id, label: student.name),
            for (final id in state.studentIds.where(
              (id) => !options.students.any((s) => s.id == id),
            ))
              NalaraDropdownOption(
                value: id,
                label: cubit.locked
                    ? lockedStudentName ?? 'Siswa tidak tersedia'
                    : 'Siswa tidak lagi aktif — hapus pilihan',
              ),
          ],
          onChanged: cubit.locked ? null : cubit.selectStudents,
        ),
        const SizedBox(height: 8),
        Text(
          cubit.locked
              ? 'Penerima aktivitas ini tetap. Buat aktivitas baru untuk siswa lain.'
              : 'Aktivitas disimpan per siswa. Jawaban dan feedback masing-masing tetap terpisah.',
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: NalaraColors.muted,
          ),
        ),
        const SizedBox(height: 18),
      ],
    ),
  );
}
