import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/domain/page.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../../../utils/validators.dart';
import '../../../access/domain/entities/referral_invitation.dart';
import '../../../access/presentation/widgets/referral_invitation_widgets.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/families_repository.dart';
import '../../domain/usecases/load_family_editor.dart';
import '../widgets/families_header.dart';
import '../widgets/families_list_body.dart';
import '../widgets/families_style.dart';
import '../widgets/family_form_header.dart';
import '../widgets/family_form_style.dart';

class FamiliesPage extends StatefulWidget {
  const FamiliesPage({super.key});
  @override
  State<FamiliesPage> createState() => _FamiliesPageState();
}

class _FamiliesPageState extends State<FamiliesPage>
    with TeachingCatalogRefresh<FamiliesPage> {
  final search = TextEditingController();
  var page = 1;
  Timer? _searchTimer;
  late final LoadCubit<PageResult<Family>> cubit =
      LoadCubit<PageResult<Family>>(
        () => getIt<FamiliesRepository>().list(
          page: page,
          search: search.text.trim(),
        ),
        isEmpty: (value) => value.items.isEmpty,
        append: appendPage,
      )..load();

  @override
  void onTeachingCatalogChanged() => _reload(resetPage: true);

  void _searchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => _reload(resetPage: true),
    );
  }

  Future<void> _reload({bool resetPage = false}) async {
    if (resetPage) page = 1;
    final current = cubit.state.value;
    await cubit.load(
      append: !resetPage && current != null && page > current.page,
    );
  }

  Future<void> _open(String route) async {
    FocusScope.of(context).unfocus();
    await context.push(route);
    if (mounted) _reload(resetPage: true);
  }

  void _back() => finishForm(context, '/teacher/more');

  @override
  void dispose() {
    _searchTimer?.cancel();
    search.dispose();
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: FamiliesStyle.cream,
    ),
    child: Theme(
      data: FamiliesStyle.theme(Theme.of(context)),
      child:
          BlocBuilder<
            LoadCubit<PageResult<Family>>,
            LoadState<PageResult<Family>>
          >(
            bloc: cubit,
            builder: (context, state) => Scaffold(
              backgroundColor: FamiliesStyle.cream,
              floatingActionButton: state.value?.items.isNotEmpty == true
                  ? FloatingActionButton.extended(
                      key: const ValueKey('families-add'),
                      heroTag: 'families-add',
                      onPressed: () => _open('/teacher/families/new'),
                      backgroundColor: FamiliesStyle.green,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah keluarga'),
                    )
                  : null,
              body: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      children: [
                        NalaraHeader(
                          child: FamiliesHeader(
                            search: search,
                            loading: state.status == LoadStatus.loading,
                            onBack: _back,
                            onRefresh: () => _reload(resetPage: true),
                            onClear: () {
                              search.clear();
                              _reload(resetPage: true);
                            },
                            onChanged: _searchChanged,
                            onSubmitted: (_) {
                              _searchTimer?.cancel();
                              _reload(resetPage: true);
                            },
                          ),
                        ),
                        Expanded(
                          child: FamiliesListBody(
                            key: const ValueKey('families-scroll'),
                            state: state,
                            onRefresh: () => _reload(resetPage: true),
                            onRetry: _reload,
                            onAdd: () => _open('/teacher/families/new'),
                            onOpen: (family) =>
                                _open('/teacher/families/${family.id}'),
                            onLoadMore: () {
                              page++;
                              cubit.load(append: true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    ),
  );
}

class FamilyFormPage extends StatefulWidget {
  final String? id;
  const FamilyFormPage({super.key, this.id});

  @override
  State<FamilyFormPage> createState() => _FamilyFormPageState();
}

class _FamilyFormPageState extends State<FamilyFormPage> {
  late LoadCubit<FamilyEditorOptions> _loader;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _loader = LoadCubit<FamilyEditorOptions>(
      () => getIt<LoadFamilyEditor>()(widget.id),
    )..load();
  }

  @override
  void didUpdateWidget(covariant FamilyFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loader.close();
      _bind();
    }
  }

  @override
  void dispose() {
    _loader.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: FamilyFormStyle.cream,
    ),
    child: Theme(
      data: FamilyFormStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: FamilyFormStyle.cream,
        body: SafeArea(
          bottom: false,
          child:
              BlocBuilder<
                LoadCubit<FamilyEditorOptions>,
                LoadState<FamilyEditorOptions>
              >(
                bloc: _loader,
                builder: (context, state) => Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: NalaraPageLayout(
                      header: FamilyFormHeader(
                        editing: widget.id != null,
                        onBack: () => finishForm(
                          context,
                          widget.id == null
                              ? '/teacher/families'
                              : '/teacher/families/${widget.id}',
                        ),
                      ),
                      body: ListView(
                        key: ValueKey(
                          'family-form-scroll-${widget.id ?? 'new'}',
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          bottom: 28 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          if (state.status == LoadStatus.error)
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: ErrorNotice(
                                state.error!,
                                retry: _loader.load,
                              ),
                            )
                          else if (state.value == null)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              child: _FamilyEditor(
                                key: ValueKey(
                                  '${state.value!.family?.id}:${state.value!.family?.version}',
                                ),
                                options: state.value!,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ),
      ),
    ),
  );
}

class _FamilyEditor extends StatefulWidget {
  final FamilyEditorOptions options;
  const _FamilyEditor({super.key, required this.options});
  @override
  State<_FamilyEditor> createState() => _FamilyEditorState();
}

class _FamilyEditorState extends State<_FamilyEditor> {
  final _form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.options.family?.parentName,
  );
  late final phone = TextEditingController(
    text: widget.options.family?.parentPhone,
  );
  late final selected = <String>{
    ...?widget.options.family?.children.map((child) => child.id),
  };
  final submit = SubmitCubit();

  Future<void> _save() async {
    if (submit.state.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Family? saved;
    final ok = await submit.run(() async {
      final family = widget.options.family;
      final draft = FamilyDraft(
        parentName: name.text,
        parentPhone: phone.text,
        studentIds: selected.toList(),
        version: family?.version,
      );
      saved = family == null
          ? await getIt<FamiliesRepository>().create(draft)
          : await getIt<FamiliesRepository>().update(family.id, draft);
    });
    if (ok && mounted) {
      successMessage(context, 'Data keluarga disimpan');
      finishForm(context, '/teacher/families/${saved!.id}');
    }
  }

  List<NalaraDropdownOption<String>> _childOptions(SubmitState state) => widget
      .options
      .students
      .map((student) {
        final belongsToAnotherFamily =
            student.familyId != null &&
            student.familyId != widget.options.family?.id;
        final selectedStudent = selected.contains(student.id);
        final disabled =
            belongsToAnotherFamily ||
            (student.status != 'active' && !selectedStudent);
        final detail = student.status == 'archived'
            ? 'Siswa diarsipkan'
            : student.grade;
        return NalaraDropdownOption<String>(
          value: student.id,
          label: '${student.name} · $detail',
          searchText: '${student.name} ${student.grade}',
          enabled: !disabled && !state.busy,
        );
      })
      .toList(growable: false);

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: submit,
    builder: (context, state) => Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            key: const ValueKey('family-form-info'),
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Satu Orang Tua menghubungkan semua anaknya.',
                  style: TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: FamilyFormStyle.ink,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Nomor HP digunakan untuk membedakan keluarga dalam data Guru, bukan sebagai OTP.',
                  style: FamilyFormStyle.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 23, 22, 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FamilyFormStyle.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Nama Orang Tua', requiredField: true),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('family-parent-name'),
                  controller: name,
                  enabled: !state.busy,
                  style: FamilyFormStyle.input,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama orang tua',
                  ),
                  validator: Validators.name,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 13),
                _label('Nomor HP Orang Tua', requiredField: true),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('family-parent-phone'),
                  controller: phone,
                  enabled: !state.busy,
                  style: FamilyFormStyle.input,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nomor HP',
                  ),
                  validator: Validators.phone,
                  maxLength: 25,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
          ),
          const SizedBox(height: 27),
          const Text(
            'Anak dalam keluarga',
            style: TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: FamilyFormStyle.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih anak-anak dari Orang Tua yang sama. Anak juga dapat ditautkan melalui form tambah/edit siswa.',
            style: FamilyFormStyle.body,
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FamilyFormStyle.line),
            ),
            child: NalaraMultiDropdown<String>(
              key: const ValueKey('family-children'),
              selectedValues: selected,
              options: _childOptions(state),
              decoration: const InputDecoration(labelText: 'Pilih anak'),
              hint: 'Pilih satu atau lebih anak',
              menuTitle: 'Pilih anak',
              searchHint: 'Cari nama siswa',
              onChanged: state.busy
                  ? null
                  : (values) => setState(() {
                      selected
                        ..clear()
                        ..addAll(values);
                    }),
            ),
          ),
          if (widget.options.students.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Belum ada siswa aktif yang dapat ditambahkan ke keluarga.',
                style: FamilyFormStyle.body,
              ),
            ),
          const SizedBox(height: 22),
          SubmitButton(
            key: const ValueKey('family-save'),
            cubit: submit,
            label: 'Simpan keluarga',
            onPressed: _save,
          ),
        ],
      ),
    ),
  );

  Widget _label(String text, {required bool requiredField}) => Text.rich(
    TextSpan(
      text: text,
      children: [
        if (requiredField)
          TextSpan(
            text: ' *',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
    style: FamilyFormStyle.label,
  );
}

class FamilyDetailPage extends StatefulWidget {
  final String id;
  const FamilyDetailPage({super.key, required this.id});
  @override
  State<FamilyDetailPage> createState() => _FamilyDetailPageState();
}

class _FamilyDetailPageState extends State<FamilyDetailPage> {
  final submit = SubmitCubit();
  @override
  void dispose() {
    submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AsyncPage<FamilyOverview>(
    title: 'Detail keluarga',
    load: () => getIt<LoadFamilyOverview>()(widget.id),
    builder: (context, data, reload) => PageBody(
      children: [
        Text(
          data.family.parentName,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        DetailRow('Nomor HP', data.family.parentPhone),
        OutlinedButton.icon(
          onPressed: () async {
            await context.push('/teacher/families/${widget.id}/edit');
            reload();
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Orang Tua & anak'),
        ),
        SectionTitle('${data.family.children.length} anak terdaftar'),
        if (data.family.children.isEmpty)
          const EmptyNotice(
            'Hubungkan anak terlebih dahulu melalui Edit Orang Tua & anak atau profil siswa.',
            imagePath: 'assets/Empty/Empty Keluarga.png',
          ),
        for (final child in data.family.children)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NalaraSurfaceCard(
              key: ValueKey(child.id),
              onTap: () async {
                await context.push('/teacher/students/${child.id}');
                reload();
              },
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7EFE5),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      child.name.isEmpty ? '?' : child.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'NalaraLora',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF155A49),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E292D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${child.grade} · ${statusLabel(child.status)}',
                          style: FamiliesStyle.body,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF1E292D),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        const SectionTitle('Kode referral Orang Tua'),
        const Text(
          'Satu kode berlaku untuk seluruh anak aktif dalam keluarga ini. Anak yang ditambahkan kemudian otomatis ikut terhubung. Kode baru menggantikan kode lama yang belum dipakai, bukan mencabut sesi yang sudah aktif.',
        ),
        const SizedBox(height: 16),
        SubmitButton(
          cubit: submit,
          label: 'Buat satu kode keluarga',
          onPressed: () async {
            ReferralInvitation? invitation;
            final ok = await submit.run(() async {
              invitation = await getIt<FamiliesRepository>().createCode(
                widget.id,
              );
            });
            if (ok && context.mounted) {
              reload();
              await showReferralCode(
                context,
                invitation!,
                title: 'Kode referral keluarga',
              );
            }
          },
        ),
        for (final invitation in data.invitations)
          ReferralInvitationTile(
            key: ValueKey(invitation.id),
            invitation: invitation,
            onRevoke: () async {
              if (!await confirmAction(
                context,
                'Cabut kode ini? Akses yang sudah terhubung tetap aktif.',
              )) {
                return;
              }
              final ok = await submit.run(
                () => getIt<FamiliesRepository>().revokeCode(
                  widget.id,
                  invitation.id,
                ),
              );
              if (ok) reload();
            },
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.no_accounts_outlined),
          label: const Text('Cabut seluruh akses Orang Tua'),
          onPressed: () async {
            if (!await confirmAction(
              context,
              'Cabut akses Orang Tua pada seluruh perangkat serta semua kode keluarga ini? Anak tidak dihapus. Untuk masuk kembali diperlukan kode baru.',
            )) {
              return;
            }
            final ok = await submit.run(
              () => getIt<FamiliesRepository>().revokeAccess(widget.id),
            );
            if (ok && context.mounted) {
              successMessage(context, 'Akses Orang Tua dicabut');
              reload();
            }
          },
        ),
      ],
    ),
  );
}
