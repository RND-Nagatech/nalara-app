import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../utils/injector.dart';
import '../../../../utils/validators.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subjects_repository.dart';
import '../widgets/subject_form_header.dart';
import '../widgets/subject_form_style.dart';

export 'subjects_list_page.dart';

class SubjectFormPage extends StatefulWidget {
  final String? id;
  const SubjectFormPage({super.key, this.id});
  @override
  State<SubjectFormPage> createState() => _SubjectFormPageState();
}

class _SubjectFormPageState extends State<SubjectFormPage> {
  LoadCubit<Subject>? _loader;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    final id = widget.id;
    _loader = id == null
        ? null
        : (LoadCubit<Subject>(() => getIt<SubjectsRepository>().get(id))
            ..load());
  }

  @override
  void didUpdateWidget(covariant SubjectFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loader?.close();
      _bind();
    }
  }

  @override
  void dispose() {
    _loader?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loader == null) return const _SubjectEditor();
    return BlocBuilder<LoadCubit<Subject>, LoadState<Subject>>(
      bloc: _loader,
      builder: (context, state) {
        if (state.value != null) {
          return _SubjectEditor(key: ValueKey(widget.id), subject: state.value);
        }
        return Theme(
          data: SubjectFormStyle.theme(Theme.of(context)),
          child: Scaffold(
            backgroundColor: SubjectFormStyle.cream,
            body: SafeArea(
              child: Column(
                children: [
                  NalaraHeader(
                    child: SubjectFormHeader(
                      editing: true,
                      onBack: () => finishForm(context, '/teacher/subjects'),
                    ),
                  ),
                  Expanded(
                    child: state.status == LoadStatus.error
                        ? ErrorNotice(state.error!, retry: _loader!.load)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SubjectEditor extends StatefulWidget {
  final Subject? subject;
  const _SubjectEditor({super.key, this.subject});

  @override
  State<_SubjectEditor> createState() => _SubjectEditorState();
}

class _SubjectEditorState extends State<_SubjectEditor> {
  final form = GlobalKey<FormState>(), submit = SubmitCubit();
  late final name = TextEditingController(text: widget.subject?.name);

  Future<void> _save() async {
    if (submit.state.busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await submit.run(() async {
      final repository = getIt<SubjectsRepository>();
      if (widget.subject == null) {
        await repository.create(name.text);
      } else {
        await repository.update(widget.subject!.id, name.text);
      }
    });
    if (ok && mounted) {
      successMessage(
        context,
        widget.subject == null
            ? 'Bidang belajar ditambahkan'
            : 'Nama bidang belajar diperbarui',
      );
      finishForm(context, '/teacher/subjects');
    }
  }

  @override
  void dispose() {
    name.dispose();
    submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: SubjectFormStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: SubjectFormStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: BlocBuilder<SubmitCubit, SubmitState>(
                bloc: submit,
                builder: (context, state) => NalaraPageLayout(
                  header: SubjectFormHeader(
                    editing: widget.subject != null,
                    onBack: state.busy
                        ? null
                        : () => finishForm(context, '/teacher/subjects'),
                  ),
                  body: ListView(
                    key: const ValueKey('subject-form-scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      SubjectFormHero(editing: widget.subject != null),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Form(
                          key: form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Nama bidang belajar',
                                  children: [
                                    TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                                style: const TextStyle(
                                  fontFamily: 'NalaraInter',
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: SubjectFormStyle.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Semantics(
                                label: 'Nama bidang belajar, wajib diisi',
                                child: TextFormField(
                                  key: const ValueKey('subject-name'),
                                  controller: name,
                                  enabled: !state.busy,
                                  validator: Validators.name,
                                  maxLength: 100,
                                  style: const TextStyle(
                                    fontFamily: 'NalaraInter',
                                    fontSize: 14,
                                    height: 1.45,
                                    color: SubjectFormStyle.ink,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _save(),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Contoh: Matematika, Piano, atau Renang',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SubmitButton(
                                key: const ValueKey('subject-save'),
                                cubit: submit,
                                label: widget.subject == null
                                    ? 'Simpan'
                                    : 'Simpan perubahan',
                                onPressed: _save,
                              ),
                            ],
                          ),
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
