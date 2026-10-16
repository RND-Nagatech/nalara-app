import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/family.dart';
import '../../domain/usecases/load_family_options.dart';

class FamilySelector extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const FamilySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  State<FamilySelector> createState() => _FamilySelectorState();
}

class _FamilySelectorState extends State<FamilySelector> {
  late final LoadCubit<List<Family>> cubit;
  @override
  void initState() {
    super.initState();
    cubit = LoadCubit<List<Family>>(() => getIt<LoadFamilies>()())..load();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LoadCubit<List<Family>>, LoadState<List<Family>>>(
    bloc: cubit,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: 'Orang Tua / keluarga',
            children: [
              TextSpan(
                text: ' (opsional)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          style: TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 13,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (state.status == LoadStatus.loading) const LinearProgressIndicator(),
        if (state.status == LoadStatus.error) ...[
          Semantics(liveRegion: true, child: Text(state.error!)),
          TextButton(
            onPressed: cubit.load,
            child: const Text('Muat ulang keluarga'),
          ),
          const Text(
            'Hubungan keluarga sebelumnya tetap dipertahankan sampai Anda memilih perubahan.',
          ),
        ],
        if (state.value != null)
          NalaraDropdown<String>(
            key: const ValueKey('family-selection'),
            value: widget.value ?? '',
            decoration: const InputDecoration(),
            menuTitle: 'Orang Tua / keluarga',
            searchHint: 'Cari nama atau nomor HP Orang Tua',
            options: [
              const NalaraDropdownOption(
                value: '',
                label: 'Belum ditautkan ke Orang Tua',
              ),
              if (widget.value != null &&
                  !state.value!.any((family) => family.id == widget.value))
                NalaraDropdownOption(
                  value: widget.value!,
                  label: 'Keluarga yang sudah terhubung',
                ),
              ...state.value!.map(
                (family) => NalaraDropdownOption(
                  value: family.id,
                  label: '${family.parentName} · ${family.parentPhone}',
                ),
              ),
            ],
            onChanged: state.status == LoadStatus.loading
                ? null
                : (value) => widget.onChanged(value == '' ? null : value),
          ),
        const SizedBox(height: 12),
        TextButton(
          key: const ValueKey('student-manage-families'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            overlayColor: Colors.transparent,
            minimumSize: const Size(48, 46),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
          onPressed: () async {
            await context.push('/teacher/families');
            if (mounted) cubit.load();
          },
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Kelola Orang Tua & keluarga',
                  style: TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
