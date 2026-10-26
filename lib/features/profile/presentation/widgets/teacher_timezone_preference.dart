import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/app_timezones.dart';
import '../../../../shared/domain/teaching_catalog_changes.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../../auth/domain/entities/teacher.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/teacher_profile_repository.dart';
import '../bloc/profile_timezone_cubit.dart';
import 'settings_style.dart';

class TeacherTimezonePreference extends StatelessWidget {
  const TeacherTimezonePreference({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = getIt<AuthCubit>();
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: auth,
      builder: (context, state) {
        final teacher = state.teacher;
        if (state.status != AuthStatus.authenticated || teacher == null) {
          return const SizedBox.shrink();
        }
        return _TimezoneEditor(
          key: ValueKey(
            '${teacher.id}:${teacher.workspaceId}:${teacher.timezone}',
          ),
          teacher: teacher,
          onSaved: (expected, timezone) {
            if (auth.updateOwnTimezone(expected, timezone) &&
                getIt.isRegistered<TeachingCatalogChanges>()) {
              getIt<TeachingCatalogChanges>().notifyChanged();
            }
          },
        );
      },
    );
  }
}

class _TimezoneEditor extends StatefulWidget {
  final Teacher teacher;
  final void Function(Teacher, String) onSaved;
  const _TimezoneEditor({
    super.key,
    required this.teacher,
    required this.onSaved,
  });
  @override
  State<_TimezoneEditor> createState() => _TimezoneEditorState();
}

class _TimezoneEditorState extends State<_TimezoneEditor> {
  late final _cubit = _createCubit();

  Future<void> _save() async {
    final auth = getIt<AuthCubit>();
    final expected = widget.teacher;
    final route = ModalRoute.of(context);
    final timezone = await _cubit.save();
    if (!mounted || timezone == null || route?.isCurrent == false) return;
    final current = auth.state.teacher;
    if (auth.state.status != AuthStatus.authenticated ||
        current?.id != expected.id ||
        current?.workspaceId != expected.workspaceId ||
        current?.timezone != timezone) {
      return;
    }
    successMessage(context, 'Zona waktu berhasil disimpan.');
  }

  ProfileTimezoneCubit _createCubit() {
    final expected = widget.teacher;
    final onSaved = widget.onSaved;
    return ProfileTimezoneCubit(
      getIt<TeacherProfileRepository>(),
      expected.timezone,
      onSaved: (timezone) => onSaved(expected, timezone),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ProfileTimezoneCubit, ProfileTimezoneState>(
    bloc: _cubit,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Zona waktu', style: SettingsStyle.body),
        const SizedBox(height: 8),
        NalaraDropdown<String>(
          key: const ValueKey('settings-timezone'),
          value: state.draft,
          enabled: !state.saving,
          menuTitle: 'Pilih zona waktu',
          options: [
            // Existing non-Indonesian IANA values stay visible until explicitly changed.
            if (!AppTimezones.supports(state.saved))
              NalaraDropdownOption(value: state.saved, label: state.saved),
            for (final entry in AppTimezones.labels.entries)
              NalaraDropdownOption(value: entry.key, label: entry.value),
          ],
          onChanged: (value) {
            if (value != null) _cubit.select(value);
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Dipakai untuk tampilan beranda, kalender, dan semua jadwal baru. Form jadwal mengikuti zona yang disimpan di sini. Waktu sesi dan zona jadwal yang sudah dibuat tetap sama.',
          style: SettingsStyle.body,
        ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              state.error!,
              key: const ValueKey('settings-timezone-error'),
              style: SettingsStyle.body.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('settings-timezone-save'),
          onPressed: state.canSave ? _save : null,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              if (state.saving)
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    key: ValueKey('settings-timezone-saving'),
                    strokeWidth: 2,
                    color: SettingsStyle.green,
                    semanticsLabel: 'Sedang menyimpan zona waktu',
                  ),
                ),
              Text(state.saving ? 'Menyimpan…' : 'Simpan zona waktu'),
            ],
          ),
        ),
      ],
    ),
  );
}
