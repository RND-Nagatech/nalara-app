import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../../../utils/validators.dart';
import '../../../families/presentation/widgets/family_selector.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/students_repository.dart';
import '../widgets/student_form_field.dart';
import '../widgets/student_form_header.dart';
import '../widgets/student_form_style.dart';

class StudentFormPage extends StatefulWidget {
  final String? id;
  const StudentFormPage({super.key, this.id});
  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  LoadCubit<Student>? _loader;
  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  void _loadStudent() {
    final id = widget.id;
    _loader = id == null
        ? null
        : (LoadCubit<Student>(() => getIt<StudentsRepository>().get(id))
            ..load());
  }

  @override
  void didUpdateWidget(covariant StudentFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loader?.close();
      _loadStudent();
    }
  }

  @override
  void dispose() {
    _loader?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: StudentFormStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: StudentFormStyle.cream,
        body: SafeArea(
          bottom: false,
          child: _loader == null
              ? _body(context)
              : BlocBuilder<LoadCubit<Student>, LoadState<Student>>(
                  bloc: _loader,
                  builder: (context, state) => _body(context, state: state),
                ),
        ),
      ),
    ),
  );

  Widget _body(BuildContext context, {LoadState<Student>? state}) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: NalaraPageLayout(
        header: StudentFormHeader(
          editing: widget.id != null,
          onBack: () => finishForm(
            context,
            widget.id == null
                ? '/teacher/students'
                : '/teacher/students/${widget.id}',
          ),
        ),
        body: ListView(
          key: ValueKey('student-form-scroll-${widget.id ?? 'new'}'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: 28 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            const StudentFormIntro(),
            if (state?.status == LoadStatus.error)
              Padding(
                padding: const EdgeInsets.all(22),
                child: ErrorNotice(state!.error!, retry: _loader!.load),
              )
            else if (_loader != null && state?.value == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _StudentEditor(
                  key: ValueKey(state?.value?.id ?? 'new'),
                  student: state?.value,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _StudentEditor extends StatefulWidget {
  final Student? student;
  const _StudentEditor({super.key, this.student});
  @override
  State<_StudentEditor> createState() => _StudentEditorState();
}

class _StudentEditorState extends State<_StudentEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.student?.name),
      _grade = TextEditingController(text: widget.student?.grade),
      _notes = TextEditingController(text: widget.student?.notes);
  final _submit = SubmitCubit();
  late String? _familyId = widget.student?.familyId;
  bool _familyChanged = false;
  @override
  void dispose() {
    _name.dispose();
    _grade.dispose();
    _notes.dispose();
    _submit.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Student? saved;
    final ok = await _submit.run(() async {
      final draft = StudentDraft(
        name: _name.text,
        grade: _grade.text,
        notes: _notes.text,
        familyId: _familyChanged || widget.student == null ? _familyId : null,
        clearFamily: _familyChanged && _familyId == null,
      );
      saved = widget.student == null
          ? await getIt<StudentsRepository>().create(draft)
          : await getIt<StudentsRepository>().update(widget.student!.id, draft);
    });
    if (ok && mounted) {
      successMessage(context, 'Data siswa disimpan');
      finishForm(context, '/teacher/students/${saved!.id}');
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentFormField(
          fieldId: 'name',
          label: 'Nama siswa',
          hint: 'Masukkan nama siswa',
          controller: _name,
          validator: Validators.name,
          maxLength: 100,
          requiredField: true,
        ),
        StudentFormField(
          fieldId: 'grade',
          label: 'Kelas / tingkat',
          hint: 'Contoh: SD Kelas 4, SMP, dll',
          controller: _grade,
          maxLength: 50,
        ),
        StudentFormField(
          fieldId: 'notes',
          label: 'Catatan internal Guru',
          hint:
              'Tambahkan catatan khusus tentang siswa (misal: gaya belajar, kebutuhan khusus, dll)',
          controller: _notes,
          maxLength: 2000,
          minLines: 4,
          maxLines: 6,
        ),
        FamilySelector(
          value: _familyId,
          onChanged: (value) => setState(() {
            _familyId = value;
            _familyChanged = true;
          }),
        ),
        const SizedBox(height: 4),
        SubmitButton(
          key: const ValueKey('student-save'),
          cubit: _submit,
          label: widget.student == null ? 'Tambah siswa' : 'Simpan perubahan',
          onPressed: _save,
        ),
      ],
    ),
  );
}
