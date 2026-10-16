import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../domain/entities/learning_goal.dart';
import '../../domain/entities/progress_form_data.dart';
import '../../domain/usecases/load_progress_form.dart';
import '../../domain/usecases/update_progress.dart';
import '../bloc/progress_form_cubit.dart';
import '../widgets/progress_form_style.dart';
import '../widgets/progress_selector.dart';
import '../widgets/progress_student_header.dart';

class UpdateProgressPage extends StatefulWidget {
  final String id;
  const UpdateProgressPage({super.key, required this.id});
  @override
  State<UpdateProgressPage> createState() => _UpdateProgressPageState();
}

class _UpdateProgressPageState extends State<UpdateProgressPage> {
  late ProgressFormCubit _loader;
  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _loader = ProgressFormCubit(getIt<LoadProgressForm>(), widget.id)..load();
  }

  @override
  void didUpdateWidget(covariant UpdateProgressPage oldWidget) {
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
    ),
    child: Theme(
      data: ProgressFormStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: ProgressFormStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: BlocBuilder<ProgressFormCubit, ProgressFormState>(
                bloc: _loader,
                builder: (context, state) => state.data == null
                    ? Column(
                        children: [
                          NalaraHeader(child: _header(context)),
                          Expanded(
                            child: state.error == null
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.all(20),
                                    child: ErrorNotice(
                                      state.error!,
                                      retry: _loader.load,
                                    ),
                                  ),
                          ),
                        ],
                      )
                    : ProgressEditor(
                        key: ValueKey(widget.id),
                        state: state,
                        reload: _loader.load,
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _header(BuildContext context, {bool busy = false}) => Padding(
  padding: const EdgeInsets.fromLTRB(12, 5, 20, 12),
  child: Row(
    children: [
      IconButton(
        key: const ValueKey('progress-back'),
        tooltip: 'Kembali ke target',
        onPressed: busy ? null : () => finishForm(context, '/teacher/targets'),
        icon: const Icon(
          Icons.arrow_back_rounded,
          size: 25,
          color: ProgressFormStyle.ink,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          'Update Progress',
          style: ProgressFormStyle.label.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  ),
);

class ProgressEditor extends StatefulWidget {
  final ProgressFormState state;
  final Future<void> Function() reload;
  const ProgressEditor({super.key, required this.state, required this.reload});
  @override
  State<ProgressEditor> createState() => _ProgressEditorState();
}

class _ProgressEditorState extends State<ProgressEditor> {
  final _form = GlobalKey<FormState>(), _submit = SubmitCubit();
  final _note = TextEditingController();
  final _scroll = ScrollController();
  late int _progress = _data.target.progress;
  String? _sessionId;
  String _visibility = 'teacher';
  bool _settings = false, _confirming = false, _showSubmitError = false;
  ProgressFormData get _data => widget.state.data!;

  @override
  void didUpdateWidget(covariant ProgressEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state.data, widget.state.data)) {
      // Only an explicit confirmed reload replaces the slider/version. Keep notes
      // and stored IDs; a missing session requires an explicit choice, not clearing.
      _progress = _data.target.progress;
      _showSubmitError = false;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _scroll.dispose();
    _submit.close();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_submit.state.busy || _confirming || widget.state.loading) return;
    if (_progress != _data.target.progress) {
      setState(() => _confirming = true);
      final confirmed = await confirmAction(
        context,
        'Muat ulang nilai progres dari backend? Pilihan progres akan diganti dengan nilai terbaru. Catatan, sesi, dan visibilitas tetap disimpan.',
      );
      if (!mounted) return;
      setState(() => _confirming = false);
      if (!confirmed) return;
    }
    await widget.reload();
  }

  Future<void> _save() async {
    if (_submit.state.busy ||
        _confirming ||
        widget.state.loading ||
        widget.state.error != null) {
      return;
    }
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _showSubmitError = true;
    final target = _data.target;
    final router = GoRouter.maybeOf(context),
        location = GoRouter.maybeOf(context)?.state.uri;
    final update = ProgressUpdate(
      progress: _progress,
      version: target.version,
      note: _note.text,
      visibility: _visibility,
      sessionId: _sessionId,
    );
    final ok = await _submit.run(
      () => getIt<UpdateProgress>()(target.id, update),
    );
    if (!mounted) return;
    final visible =
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        (router == null || router.state.uri == location);
    if (!visible) return;
    if (ok) {
      successMessage(context, 'Progress dan riwayat disimpan');
      finishForm(context, '/teacher/targets/${Uri.encodeComponent(target.id)}');
    } else if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: _submit,
    builder: (context, submit) {
      final enabled = !submit.busy && !_confirming && !widget.state.loading;
      return Column(
        children: [
          NalaraHeader(
            child: _header(context, busy: submit.busy || _confirming),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: Form(
                key: _form,
                child: ListView(
                  key: const ValueKey('progress-form-scroll'),
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
                  children: [
                    // A finite form stays mounted together so offscreen fields
                    // still participate in validation and preserve focus/state.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.state.loading)
                          const LinearProgressIndicator(),
                        if (widget.state.error != null)
                          ErrorNotice(widget.state.error!, retry: _reload),
                        ProgressStudentHeader(data: _data),
                        const SizedBox(height: 28),
                        ProgressSelector(
                          value: _progress,
                          onChanged: enabled
                              ? (value) => setState(() => _progress = value)
                              : null,
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'Catatan perkembangan',
                          style: ProgressFormStyle.label,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          key: const ValueKey('progress-note'),
                          controller: _note,
                          enabled: enabled,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: 3000,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: ProgressFormStyle.body.copyWith(
                            color: ProgressFormStyle.ink,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Tulis catatan perkembangan siswa...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Hubungkan dengan sesi (opsional)',
                          style: ProgressFormStyle.label,
                        ),
                        const SizedBox(height: 10),
                        NalaraDropdown<String>(
                          key: const ValueKey('progress-session'),
                          value: _sessionId ?? '',
                          enabled: enabled,
                          menuTitle: 'Hubungkan dengan sesi',
                          searchHint: 'Cari tanggal atau sesi...',
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.event_note_outlined),
                          ),
                          options: [
                            const NalaraDropdownOption(
                              value: '',
                              label: 'Tanpa sesi',
                            ),
                            ..._data.lessons.map(
                              (lesson) => NalaraDropdownOption(
                                value: lesson.id,
                                label: ProgressFormStyle.sessionLabel(lesson),
                                searchText:
                                    '${lesson.studentName} ${lesson.subjectName}',
                              ),
                            ),
                          ],
                          validator: (value) =>
                              value == '' ||
                                  _data.lessons.any(
                                    (lesson) => lesson.id == value,
                                  )
                              ? null
                              : 'Sesi tidak tersedia. Pilih sesi lain atau Tanpa sesi.',
                          onChanged: (value) => setState(
                            () => _sessionId = value == '' ? null : value,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const ValueKey('progress-settings'),
                            onPressed: enabled
                                ? () => setState(() => _settings = !_settings)
                                : null,
                            child: Text(
                              _settings
                                  ? 'Tutup pengaturan catatan'
                                  : 'Visibilitas: ${_visibility == 'teacher' ? 'Hanya Guru' : _visibility == 'student' ? 'Hanya Siswa' : 'Siswa / Orang Tua'}',
                              style: ProgressFormStyle.body.copyWith(
                                fontSize: 11.5,
                                color: ProgressFormStyle.green,
                              ),
                            ),
                          ),
                        ),
                        if (_settings) ...[
                          NalaraDropdown<String>(
                            key: const ValueKey('progress-visibility'),
                            enabled: enabled,
                            value: _visibility,
                            menuTitle: 'Visibilitas catatan',
                            options: const [
                              NalaraDropdownOption(
                                value: 'teacher',
                                label: 'Hanya Guru',
                              ),
                              NalaraDropdownOption(
                                value: 'student',
                                label: 'Hanya Siswa',
                              ),
                              NalaraDropdownOption(
                                value: 'shared',
                                label: 'Untuk siswa / Orang Tua',
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _visibility = value!),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Nilai sebelumnya, catatan, waktu server, dan pengubah akan dicatat dalam riwayat.',
                            style: ProgressFormStyle.body,
                          ),
                          TextButton(
                            key: const ValueKey('progress-reload-settings'),
                            onPressed: enabled ? _reload : null,
                            child: const Text('Muat ulang nilai terbaru'),
                          ),
                        ],
                        if (submit.error != null && _showSubmitError) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              submit.error!,
                              key: const ValueKey('progress-submit-error'),
                              style: ProgressFormStyle.body.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          TextButton(
                            key: const ValueKey('progress-reload-error'),
                            onPressed: enabled ? _reload : null,
                            child: const Text('Muat ulang nilai terbaru'),
                          ),
                        ],
                        const SizedBox(height: 10),
                        FilledButton(
                          key: const ValueKey('progress-save'),
                          onPressed: enabled && widget.state.error == null
                              ? _save
                              : null,
                          child: submit.busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Simpan Progress'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
