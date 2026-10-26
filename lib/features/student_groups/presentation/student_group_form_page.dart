import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/domain/teaching_catalog_changes.dart';
import '../../../shared/state/load_cubit.dart';
import '../../../shared/state/teaching_catalog_refresh.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../../shared/widgets/nalara_dropdown.dart';
import '../../../shared/widgets/nalara_header.dart';
import '../../../shared/widgets/nalara_page_header.dart';
import '../../../shared/widgets/nalara_surface_card.dart';
import '../../../shared/widgets/page_widgets.dart';
import '../../../utils/color.dart';
import '../../../utils/injector.dart';
import '../../schedules/presentation/widgets/schedule_form_style.dart';
import '../domain/load_student_group_editor.dart';
import '../domain/student_groups_repository.dart';

class StudentGroupFormPage extends StatefulWidget {
  final String? id;
  const StudentGroupFormPage({super.key, this.id});
  @override
  State<StudentGroupFormPage> createState() => _StudentGroupFormPageState();
}

class _StudentGroupFormPageState extends State<StudentGroupFormPage>
    with TeachingCatalogRefresh<StudentGroupFormPage> {
  late final _loader = LoadCubit<StudentGroupEditorData>(
    () => getIt<LoadStudentGroupEditor>()(widget.id),
  )..load();
  @override
  void onTeachingCatalogChanged() => _loader.load();
  @override
  void didUpdateWidget(covariant StudentGroupFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _loader.load();
  }

  @override
  void dispose() {
    _loader.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ScheduleFormStyle.theme(Theme.of(context)),
    child: Scaffold(
      backgroundColor: NalaraColors.cream,
      body:
          BlocBuilder<
            LoadCubit<StudentGroupEditorData>,
            LoadState<StudentGroupEditorData>
          >(
            bloc: _loader,
            builder: (context, state) {
              if (state.value != null && state.value!.group?.id == widget.id) {
                return _GroupEditor(
                  key: ValueKey(widget.id ?? 'new'),
                  data: state.value!,
                  error: state.error,
                  reload: _loader.load,
                  addStudent: () async {
                    await context.push('/teacher/students/new');
                    if (mounted) await _loader.load();
                  },
                );
              }
              return NalaraPageLayout(
                header: NalaraPageHeader(
                  title: widget.id == null
                      ? 'Tambah grup siswa'
                      : 'Edit grup siswa',
                ),
                body: state.error != null
                    ? ErrorNotice(state.error!, retry: _loader.load)
                    : const Center(child: CircularProgressIndicator()),
              );
            },
          ),
    ),
  );
}

class _GroupEditor extends StatefulWidget {
  final StudentGroupEditorData data;
  final String? error;
  final Future<void> Function() reload, addStudent;
  const _GroupEditor({
    super.key,
    required this.data,
    this.error,
    required this.reload,
    required this.addStudent,
  });
  @override
  State<_GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends State<_GroupEditor> {
  final _form = GlobalKey<FormState>();
  final _submit = SubmitCubit();
  late final _group = widget.data.group;
  late final _name = TextEditingController(text: _group?.name ?? '');
  late Set<String> _ids = {...?_group?.studentIds};
  bool _confirming = false;
  @override
  void dispose() {
    _name.dispose();
    _submit.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submit.state.busy || _confirming || !_form.currentState!.validate()) {
      return;
    }
    final ok = await _submit.run(
      () => getIt<StudentGroupsRepository>().save(
        id: _group?.id,
        version: _group?.version,
        name: _name.text,
        studentIds: List.of(_ids),
      ),
    );
    if (ok && mounted) {
      getIt<TeachingCatalogChanges>().notifyChanged();
      successMessage(context, 'Grup siswa disimpan');
      finishForm(context, '/teacher/student-groups');
    }
  }

  Future<void> _remove() async {
    if (_submit.state.busy || _confirming || _group == null) return;
    setState(() => _confirming = true);
    final confirmed = await confirmAction(
      context,
      'Hapus grup ${_group.name}? Data siswa dan jadwal yang sudah dibuat tetap tersimpan.',
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (!confirmed) return;
    final ok = await _submit.run(
      () => getIt<StudentGroupsRepository>().remove(_group.id, _group.version),
    );
    if (ok && mounted) {
      getIt<TeachingCatalogChanges>().notifyChanged();
      successMessage(context, 'Grup siswa dihapus');
      finishForm(context, '/teacher/student-groups');
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: _submit,
    builder: (context, state) {
      final busy = state.busy || _confirming;
      final students = widget.data.students;
      final availableIds = students.map((s) => s.id).toSet();
      final missing = _ids.difference(availableIds);
      return PopScope(
        canPop: !busy,
        child: NalaraPageLayout(
          header: NalaraPageHeader(
            title: _group == null ? 'Tambah grup siswa' : 'Edit grup siswa',
            backEnabled: !busy,
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Satu grup, lebih mudah mengatur jadwal.',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: NalaraColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih siswa yang biasa belajar bersama. Satu siswa boleh tergabung di beberapa grup.',
                      style: TextStyle(color: NalaraColors.muted, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    if (widget.error != null) ...[
                      Text(
                        'Daftar siswa belum dapat diperbarui. ${widget.error}',
                        style: const TextStyle(color: NalaraColors.danger),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: busy ? null : widget.reload,
                          child: const Text('Coba lagi'),
                        ),
                      ),
                    ],
                    NalaraSurfaceCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Nama grup',
                            style: ScheduleFormStyle.label,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _name,
                            enabled: !busy,
                            maxLength: 100,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Matematika kelas 4',
                            ),
                            validator: (value) =>
                                (value?.trim().length ?? 0) < 2
                                ? 'Nama grup minimal 2 karakter'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Anggota grup',
                            style: ScheduleFormStyle.label,
                          ),
                          const SizedBox(height: 8),
                          NalaraMultiDropdown<String>(
                            selectedValues: _ids,
                            enabled: !busy,
                            menuTitle: 'Pilih anggota grup',
                            searchHint: 'Cari nama siswa...',
                            hint: 'Pilih satu atau beberapa siswa',
                            options: [
                              for (final student in students)
                                NalaraDropdownOption(
                                  value: student.id,
                                  label: student.grade.isEmpty
                                      ? student.name
                                      : '${student.name} · ${student.grade}',
                                ),
                              for (final id in missing)
                                NalaraDropdownOption(
                                  value: id,
                                  label:
                                      '${_group?.students.where((s) => s.id == id).firstOrNull?.name ?? 'Siswa'} — tidak aktif, hapus pilihan',
                                ),
                            ],
                            validator: (values) {
                              if (values == null || values.isEmpty) {
                                return 'Pilih minimal satu siswa';
                              }
                              if (values.length > 100) {
                                return 'Maksimal 100 siswa per grup';
                              }
                              if (values.any(
                                (id) => !availableIds.contains(id),
                              )) {
                                return 'Hapus anggota yang sudah tidak aktif sebelum menyimpan';
                              }
                              return null;
                            },
                            onChanged: (values) =>
                                setState(() => _ids = Set.of(values)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_ids.length} siswa dipilih',
                            style: ScheduleFormStyle.supporting,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: busy ? null : widget.addStudent,
                              child: const Text('Tambah siswa baru'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SubmitButton(
                      cubit: _submit,
                      label: 'Simpan grup',
                      onPressed: _save,
                    ),
                    if (_group != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Perubahan anggota berlaku saat grup dipilih untuk jadwal baru.',
                        style: ScheduleFormStyle.supporting,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: busy ? null : _remove,
                        style: TextButton.styleFrom(
                          foregroundColor: NalaraColors.danger,
                        ),
                        child: const Text('Hapus grup'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
