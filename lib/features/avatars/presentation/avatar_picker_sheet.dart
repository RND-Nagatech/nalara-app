import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/widgets/nalara_avatar.dart';
import '../../../utils/color.dart';
import '../domain/avatar.dart';
import 'avatar_picker_cubit.dart';

Future<AvatarSelection?> showAvatarPicker(
  BuildContext context, {
  required AvatarsRepository repository,
  required String name,
  String? current,
}) async {
  final cubit = AvatarPickerCubit(repository, current)..load();
  try {
    return await showModalBottomSheet<AvatarSelection>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: NalaraColors.cream,
      showDragHandle: false,
      useSafeArea: true,
      builder: (_) => _AvatarPicker(cubit: cubit, name: name),
    );
  } finally {
    await cubit.close();
  }
}

class _AvatarPicker extends StatelessWidget {
  final AvatarPickerCubit cubit;
  final String name;
  const _AvatarPicker({required this.cubit, required this.name});
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<AvatarPickerCubit, AvatarPickerState>(
    bloc: cubit,
    listenWhen: (_, state) => state.saved != null,
    listener: (context, state) => Navigator.of(context).pop(state.saved),
    builder: (context, state) => PopScope(
      canPop: !state.saving,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pilih foto profil',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: NalaraColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: state.saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih karakter yang paling cocok dengan Anda.',
                  style: TextStyle(color: NalaraColors.muted),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : state.options.isEmpty
                      ? Center(
                          child: TextButton(
                            onPressed: cubit.load,
                            child: const Text('Muat ulang pilihan karakter'),
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: _choice(
                                context,
                                state,
                                null,
                                'Gunakan inisial nama',
                              ),
                            ),
                            for (final category in [
                              'student',
                              'adult',
                              'teacher',
                            ])
                              if (state.options.any(
                                (option) => option.category == category,
                              )) ...[
                                SliverPadding(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 10,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: Text(
                                      switch (category) {
                                        'teacher' => 'Karakter guru',
                                        'adult' => 'Karakter dewasa',
                                        _ => 'Karakter anak kecil',
                                      },
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: NalaraColors.ink,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverLayoutBuilder(
                                  builder: (context, constraints) => SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              constraints.crossAxisExtent < 300
                                              ? 2
                                              : 3,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                        ),
                                    delegate: SliverChildListDelegate([
                                      for (final option in state.options.where(
                                        (option) => option.category == category,
                                      ))
                                        _choice(
                                          context,
                                          state,
                                          option.id,
                                          option.label,
                                        ),
                                    ]),
                                  ),
                                ),
                              ],
                          ],
                        ),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: NalaraColors.danger),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const ValueKey('avatar-save'),
                  onPressed:
                      state.saving || state.loading || state.options.isEmpty
                      ? null
                      : cubit.save,
                  child: state.saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan foto profil'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _choice(
    BuildContext context,
    AvatarPickerState state,
    String? id,
    String label,
  ) {
    final selected = state.selected == id;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: Material(
        key: ValueKey('avatar-option-${id ?? 'initials'}'),
        color: selected ? NalaraColors.lightGreen : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? NalaraColors.green : NalaraColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: state.saving ? null : () => cubit.select(id),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: id == null
                ? Row(
                    children: [
                      NalaraAvatar(name: name, size: 44),
                      const SizedBox(width: 12),
                      Expanded(child: Text(label)),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: NalaraColors.green,
                        ),
                    ],
                  )
                : Stack(
                    children: [
                      Center(
                        child: LayoutBuilder(
                          builder: (_, constraints) => NalaraAvatar(
                            name: name,
                            avatarId: id,
                            size: constraints.maxHeight.clamp(36, 88),
                          ),
                        ),
                      ),
                      if (selected)
                        const Align(
                          alignment: Alignment.topRight,
                          child: Icon(
                            Icons.check_circle,
                            color: NalaraColors.green,
                            size: 21,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
