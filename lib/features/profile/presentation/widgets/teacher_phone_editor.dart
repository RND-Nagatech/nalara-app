import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../utils/injector.dart';
import '../../../auth/domain/entities/teacher.dart';
import '../../../auth/domain/value_objects/phone_number.dart';
import '../../domain/teacher_profile_repository.dart';
import '../bloc/profile_phone_cubit.dart';
import 'profile_style.dart';

class TeacherPhoneEditor extends StatefulWidget {
  final Teacher teacher;
  final TeacherProfileRepository? repository;
  final void Function(Teacher expected, String phone) onSaved;
  final ValueChanged<bool>? onEditingChanged;
  final bool enabled;
  const TeacherPhoneEditor({
    super.key,
    required this.teacher,
    required this.onSaved,
    this.repository,
    this.onEditingChanged,
    this.enabled = true,
  });
  @override
  State<TeacherPhoneEditor> createState() => _TeacherPhoneEditorState();
}

class _TeacherPhoneEditorState extends State<TeacherPhoneEditor> {
  late final _cubit = ProfilePhoneCubit(
    widget.repository ?? getIt<TeacherProfileRepository>(),
  );
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void didUpdateWidget(TeacherPhoneEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teacher.id != widget.teacher.id ||
        oldWidget.teacher.workspaceId != widget.teacher.workspaceId) {
      _cubit.cancel();
      _controller.clear();
      _focus.unfocus();
    }
  }

  void _edit() {
    _controller.text = widget.teacher.phone ?? '';
    _cubit.edit(widget.teacher.phone);
    widget.onEditingChanged?.call(true);
    _focus.requestFocus();
  }

  void _cancel() {
    _cubit.cancel();
    _focus.unfocus();
    widget.onEditingChanged?.call(false);
  }

  Future<void> _save() async {
    final expected = widget.teacher;
    final phone = await _cubit.save();
    if (!mounted || phone == null) return;
    _focus.unfocus();
    widget.onSaved(expected, phone);
    widget.onEditingChanged?.call(false);
  }

  @override
  void dispose() {
    _cubit.close();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ProfilePhoneCubit, ProfilePhoneState>(
    bloc: _cubit,
    builder: (context, state) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nomor HP',
                  style: ProfileStyle.body.copyWith(fontSize: 12),
                ),
              ),
              if (!state.editing && widget.teacher.missingPhone)
                Text(
                  'Belum diisi',
                  style: ProfileStyle.body.copyWith(
                    fontSize: 11,
                    color: ProfileStyle.danger,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: state.editing
                    ? TextField(
                        key: const ValueKey('profile-phone-input'),
                        controller: _controller,
                        focusNode: _focus,
                        enabled: !state.saving,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        maxLength: 32,
                        onChanged: _cubit.change,
                        onSubmitted: (_) {
                          if (state.canSave) _save();
                        },
                        style: ProfileStyle.body.copyWith(
                          color: ProfileStyle.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan nomor HP',
                          counterText: '',
                          filled: true,
                          fillColor: ProfileStyle.paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SelectableText(
                          widget.teacher.missingPhone
                              ? 'Belum ditambahkan'
                              : widget.teacher.phone!,
                          style: ProfileStyle.body.copyWith(
                            color: ProfileStyle.ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const ValueKey('profile-phone-action'),
                tooltip: state.editing ? 'Simpan nomor HP' : 'Edit nomor HP',
                onPressed: !widget.enabled || state.saving
                    ? null
                    : state.editing
                    ? (state.canSave ? _save : null)
                    : _edit,
                color: ProfileStyle.green,
                icon: state.saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        state.editing
                            ? Icons.check_rounded
                            : Icons.edit_outlined,
                        size: 21,
                      ),
              ),
            ],
          ),
          if (state.editing) ...[
            const SizedBox(height: 4),
            Text(
              'Gunakan nomor HP aktif agar orang tua dapat menghubungi Anda.',
              style: ProfileStyle.body.copyWith(fontSize: 11),
            ),
            if (state.draft.trim().isNotEmpty &&
                PhoneNumber.normalize(state.draft) == null)
              Text(
                'Nomor HP Indonesia tidak valid. Contoh: 081234567890.',
                style: ProfileStyle.body.copyWith(
                  fontSize: 11,
                  color: ProfileStyle.danger,
                ),
              ),
            if (state.error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  state.error!,
                  key: const ValueKey('profile-phone-error'),
                  style: ProfileStyle.body.copyWith(
                    fontSize: 12,
                    color: ProfileStyle.danger,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('profile-phone-cancel'),
                onPressed: state.saving ? null : _cancel,
                child: const Text('Batal'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
