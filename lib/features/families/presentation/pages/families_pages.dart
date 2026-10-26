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
import '../../../../utils/date_time_utils.dart';
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
        const SizedBox(height: 6),
        Text(
          data.family.parentName,
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: FamiliesStyle.ink,
          ),
        ),
        const SizedBox(height: 14),
        const Text('Nomor HP', style: FamiliesStyle.body),
        const SizedBox(height: 5),
        Text(
          data.family.parentPhone,
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 16,
            height: 1.3,
            color: FamiliesStyle.ink,
          ),
        ),
        const SizedBox(height: 18),
        _FamilyDetailAction(
          label: 'Edit Orang Tua & anak',
          onTap: () async {
            await context.push('/teacher/families/${widget.id}/edit');
            if (context.mounted) reload();
          },
        ),
        const SizedBox(height: 30),
        _FamilyDetailSectionTitle(
          '${data.family.children.length} anak terdaftar',
        ),
        const SizedBox(height: 12),
        if (data.family.children.isEmpty)
          const EmptyNotice(
            'Hubungkan anak terlebih dahulu melalui Edit Orang Tua & anak atau profil siswa.',
            imagePath: 'assets/Empty/Empty Keluarga.png',
          )
        else
          NalaraSurfaceCard(
            key: const ValueKey('family-children-group'),
            radius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (
                  var index = 0;
                  index < data.family.children.length;
                  index++
                ) ...[
                  if (index > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 74,
                      endIndent: 16,
                      color: FamiliesStyle.line,
                    ),
                  _FamilyChildRow(
                    key: ValueKey(data.family.children[index].id),
                    child: data.family.children[index],
                    onTap: () async {
                      await context.push(
                        '/teacher/students/${data.family.children[index].id}',
                      );
                      if (context.mounted) reload();
                    },
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 28),
        const _FamilyDetailSectionTitle('Kode referral Orang Tua'),
        const SizedBox(height: 10),
        const Text(
          'Satu kode dapat digunakan kembali tanpa batas waktu untuk seluruh anak aktif dalam keluarga ini. Anak yang ditambahkan kemudian otomatis ikut terhubung. Kode baru menonaktifkan kode sebelumnya, tanpa memutus akses yang sudah terhubung. Simpan kode saat dibuat.',
          style: TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 13.5,
            height: 1.5,
            color: FamiliesStyle.muted,
          ),
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
        for (final invitation in data.invitations.take(1))
          _FamilyInvitationCard(
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
              if (ok && context.mounted) reload();
            },
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(height: 1, color: FamiliesStyle.line),
        ),
        _FamilyDetailAction(
          label: 'Cabut seluruh akses Orang Tua',
          onTap: () async {
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
        const SizedBox(height: 18),
      ],
    ),
  );
}

class _FamilyDetailSectionTitle extends StatelessWidget {
  final String title;

  const _FamilyDetailSectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontFamily: 'NalaraInter',
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: FamiliesStyle.ink,
    ),
  );
}

class _FamilyDetailAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FamilyDetailAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: FamiliesStyle.line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 13, 14, 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: FamiliesStyle.green,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: FamiliesStyle.ink,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _FamilyChildRow extends StatelessWidget {
  final FamilyChild child;
  final VoidCallback onTap;

  const _FamilyChildRow({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: FamiliesStyle.sage,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              child.name.isEmpty ? '?' : child.name[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'NalaraLora',
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: FamiliesStyle.green,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: FamiliesStyle.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${child.grade} · ${statusLabel(child.status)}',
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 13.5,
                    height: 1.4,
                    color: FamiliesStyle.muted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: FamiliesStyle.ink,
            size: 24,
          ),
        ],
      ),
    ),
  );
}

class _FamilyInvitationCard extends StatelessWidget {
  final ReferralInvitation invitation;
  final VoidCallback onRevoke;

  const _FamilyInvitationCard({
    super.key,
    required this.invitation,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final lastUsed = invitation.lastUsedAt ?? invitation.redeemedAt;
    final status = invitation.revokedAt != null
        ? 'Dicabut'
        : lastUsed != null
        ? 'Aktif · Terakhir digunakan ${DateTimeUtils.date(lastUsed)}'
        : 'Aktif · Belum digunakan';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: NalaraSurfaceCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invitation.expiresAt == null
                        ? 'Berlaku tanpa batas waktu'
                        : 'Berlaku sampai ${DateTimeUtils.date(invitation.expiresAt!)}',
                    style: const TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: FamiliesStyle.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(status, style: FamiliesStyle.body),
                ],
              ),
            ),
            if (invitation.revokedAt == null)
              TextButton(
                onPressed: onRevoke,
                style: TextButton.styleFrom(
                  foregroundColor: FamiliesStyle.green,
                  backgroundColor: FamiliesStyle.sage,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Cabut kode'),
              ),
          ],
        ),
      ),
    );
  }
}
