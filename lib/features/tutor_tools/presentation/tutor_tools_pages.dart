import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/state/load_cubit.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../../shared/widgets/nalara_dropdown.dart';
import '../../../shared/widgets/nalara_page_header.dart';
import '../../../shared/widgets/page_widgets.dart';
import '../../../utils/color.dart';
import '../../../utils/injector.dart';
import '../../subscription/presentation/subscription_cubit.dart';
import '../domain/load_tutor_catalog.dart';
import '../domain/tutor_tools.dart';

Widget toolCard(Widget child) => Container(
  margin: const EdgeInsets.only(bottom: 14),
  padding: const EdgeInsets.all(21),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: NalaraColors.line),
  ),
  child: child,
);
Widget toolIntro(String title, String description) => Padding(
  padding: const EdgeInsets.fromLTRB(2, 12, 2, 24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'NALARA · RUANG TUMBUH',
        style: TextStyle(
          color: NalaraColors.green,
          fontSize: 10,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        title,
        style: const TextStyle(
          fontSize: 27,
          height: 1.3,
          fontWeight: FontWeight.w800,
          color: NalaraColors.ink,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        description,
        style: const TextStyle(color: NalaraColors.muted, height: 1.65),
      ),
    ],
  ),
);

class ProToolsGate extends StatelessWidget {
  final String feature;
  final Widget child;
  const ProToolsGate({super.key, required this.feature, required this.child});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SubscriptionCubit, SubscriptionState>(
    bloc: getIt<SubscriptionCubit>(),
    builder: (context, state) {
      if (state.value?.has(feature) == true && !state.blocked) return child;
      return NalaraPageScaffold(
        title: 'Ruang kerja Pro',
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/teacher/profile'),
        body: PageBody(
          children: [
            toolIntro(
              'Beri ruang lebih\nuntuk perkembangan.',
              'Nikmati alat yang membantu Anda mengajar lebih efisien dan menyampaikan perkembangan dengan lebih baik.',
            ),
            toolCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.value?.featureLabels[feature] ?? 'Fitur Tutor Pro',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tersedia selama Trial dan dalam paket Tutor Pro.',
                    style: TextStyle(color: NalaraColors.muted, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.push('/teacher/subscription'),
                    child: const Text('Lihat pilihan paket'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> shareTutorFiles(
  BuildContext context,
  List<TutorExport> files,
) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: files
          .map(
            (file) => XFile.fromData(
              Uint8List.fromList(file.bytes),
              mimeType: file.mimeType,
              name: file.filename,
            ),
          )
          .toList(),
      fileNameOverrides: files.map((f) => f.filename).toList(),
      sharePositionOrigin: box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    ),
  );
}

class ReportPdfButton extends StatefulWidget {
  final String reportId;
  const ReportPdfButton({super.key, required this.reportId});
  @override
  State<ReportPdfButton> createState() => _ReportPdfButtonState();
}

class _ReportPdfButtonState extends State<ReportPdfButton> {
  final _submit = SubmitCubit();
  @override
  void dispose() {
    _submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: _submit,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: state.busy
              ? null
              : () async {
                  if (getIt<SubscriptionCubit>().state.value?.has(
                        'pdfExport',
                      ) !=
                      true) {
                    context.push('/teacher/subscription');
                    return;
                  }
                  await _submit.run(() async {
                    final file = await getIt<TutorToolsRepository>().reportPdf(
                      widget.reportId,
                    );
                    if (context.mounted) await shareTutorFiles(context, [file]);
                  });
                },
          icon: const Icon(Icons.file_download_outlined, size: 19),
          label: Text(state.busy ? 'Menyiapkan PDF…' : 'Export laporan PDF'),
        ),
        if (state.error != null)
          Text(state.error!, style: const TextStyle(color: Colors.red)),
      ],
    ),
  );
}

class ActivitiesPage extends StatelessWidget {
  final String role;
  const ActivitiesPage({super.key, this.role = 'teacher'});
  @override
  Widget build(BuildContext context) {
    final page = PagedListPage<LearningActivity>(
      title: 'Tugas & materi',
      emptyArtwork: 'assets/Empty/empty siswa.png',
      empty: role == 'teacher'
          ? 'Bagikan tugas dan materi belajar pertama Anda.'
          : 'Belum ada tugas atau materi yang dibagikan Guru.',
      newRoute: role == 'teacher' ? '/teacher/materials/new' : null,
      load: (page) => getIt<TutorToolsRepository>().activities(
        page: page,
        portal: role != 'teacher',
      ),
      itemBuilder: (context, item, reload) => toolCard(
        InkWell(
          onTap: () async {
            await context.push('/$role/assignments/${item.id}');
            if (context.mounted) reload();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.kind == 'task' ? 'TUGAS' : 'MATERI',
                style: const TextStyle(
                  color: NalaraColors.green,
                  letterSpacing: 1.4,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  item.studentName,
                  item.subjectName,
                ].where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(color: NalaraColors.muted),
              ),
              if (item.dueAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Batas: ${DateFormat('d MMM yyyy HH:mm', 'id_ID').format(item.dueAt!.toLocal())}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: NalaraColors.muted,
                    ),
                  ),
                ),
              if (role == 'teacher')
                Text(
                  item.status == 'published'
                      ? 'Dibagikan'
                      : item.status == 'archived'
                      ? 'Diarsipkan'
                      : 'Draft',
                  style: const TextStyle(color: NalaraColors.green, height: 2),
                ),
            ],
          ),
        ),
      ),
    );
    return role == 'teacher'
        ? ProToolsGate(feature: 'assignments', child: page)
        : page;
  }
}

class ActivityDetailPage extends StatefulWidget {
  final String id, role;
  const ActivityDetailPage({
    super.key,
    required this.id,
    this.role = 'teacher',
  });
  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  final _submit = SubmitCubit();
  Future<LearningActivity> _load() => getIt<TutorToolsRepository>().activity(
    widget.id,
    portal: widget.role != 'teacher',
  );
  @override
  void dispose() {
    _submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AsyncPage<LearningActivity>(
    title: 'Aktivitas belajar',
    load: _load,
    builder: (context, item, reload) => PageBody(
      children: [
        toolIntro(
          item.title,
          item.kind == 'task'
              ? 'Latihan terarah untuk langkah belajar berikutnya.'
              : 'Materi pendamping perjalanan belajar.',
        ),
        toolCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.content,
                style: const TextStyle(fontSize: 15, height: 1.8),
              ),
              if (item.dueAt != null) ...[
                const Divider(height: 30),
                Text(
                  'Batas pengumpulan: ${DateFormat('d MMMM yyyy HH:mm', 'id_ID').format(item.dueAt!.toLocal())}',
                ),
              ],
              if (widget.role == 'teacher')
                TextButton(
                  onPressed: () async {
                    await context.push('/teacher/materials/new', extra: item);
                    if (context.mounted) reload();
                  },
                  child: const Text('Edit aktivitas'),
                ),
            ],
          ),
        ),
        if (item.kind == 'task') ...[
          for (final answer in item.submissions)
            toolCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Jawaban siswa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(answer.text, style: const TextStyle(height: 1.7)),
                  const SizedBox(height: 16),
                  Text(
                    answer.feedback.isEmpty
                        ? 'Belum ada tanggapan Guru.'
                        : 'Tanggapan Guru\n${answer.feedback}',
                    style: const TextStyle(
                      color: NalaraColors.green,
                      height: 1.7,
                    ),
                  ),
                  if (widget.role == 'teacher')
                    TextButton(
                      onPressed: () async {
                        await context.push(
                          '/teacher/submissions/${answer.id}/feedback',
                          extra: answer,
                        );
                        if (context.mounted) reload();
                      },
                      child: const Text('Beri tanggapan'),
                    ),
                ],
              ),
            ),
          if (widget.role == 'student' &&
              item.submissions.every((s) => s.reviewedAt == null))
            _AnswerEditor(
              id: item.id,
              previous: item.submissions.firstOrNull,
              onSaved: reload,
            ),
        ],
      ],
    ),
  );
}

class _AnswerEditor extends StatefulWidget {
  final String id;
  final ActivitySubmission? previous;
  final VoidCallback onSaved;
  const _AnswerEditor({required this.id, this.previous, required this.onSaved});
  @override
  State<_AnswerEditor> createState() => _AnswerEditorState();
}

class _AnswerEditorState extends State<_AnswerEditor> {
  late final _text = TextEditingController(text: widget.previous?.text);
  final _submit = SubmitCubit();
  @override
  void dispose() {
    _text.dispose();
    _submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => toolCard(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tulis jawaban Anda',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _text,
          minLines: 5,
          maxLines: 12,
          maxLength: 10000,
          decoration: const InputDecoration(
            hintText: 'Tuliskan hasil latihan atau catatan belajar…',
          ),
        ),
        SubmitButton(
          cubit: _submit,
          label: 'Kirim jawaban',
          onPressed: () async {
            final ok = await _submit.run(
              () => getIt<TutorToolsRepository>().submit(
                widget.id,
                _text.text,
                widget.previous?.version ?? 0,
              ),
            );
            if (ok && context.mounted) {
              successMessage(context, 'Jawaban berhasil dikirim.');
              widget.onSaved();
            }
          },
        ),
      ],
    ),
  );
}

class ActivityFormPage extends StatefulWidget {
  final LearningActivity? activity;
  const ActivityFormPage({super.key, this.activity});
  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  late final Future<TutorCatalog> Function() _load =
      getIt<LoadTutorCatalog>().call;
  @override
  Widget build(BuildContext context) => ProToolsGate(
    feature: 'assignments',
    child: AsyncPage<TutorCatalog>(
      title: widget.activity == null ? 'Tambah aktivitas' : 'Edit aktivitas',
      load: _load,
      builder: (context, catalog, reload) =>
          _ActivityEditor(catalog: catalog, activity: widget.activity),
    ),
  );
}

class _ActivityEditor extends StatefulWidget {
  final TutorCatalog catalog;
  final LearningActivity? activity;
  const _ActivityEditor({required this.catalog, this.activity});
  @override
  State<_ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends State<_ActivityEditor> {
  final _form = GlobalKey<FormState>(), _submit = SubmitCubit();
  late final _title = TextEditingController(text: widget.activity?.title),
      _content = TextEditingController(text: widget.activity?.content);
  late String? _student = widget.activity?.studentId,
      _subject = widget.activity?.subjectId;
  late String _kind = widget.activity?.kind ?? 'task',
      _status = widget.activity?.status ?? 'draft',
      _visibility = widget.activity?.visibility ?? 'shared';
  late DateTime? _due = widget.activity?.dueAt;
  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _submit.close();
    super.dispose();
  }

  Widget _choice(
    String label,
    String? value,
    List<(String, String)> values,
    ValueChanged<String?>? onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: NalaraDropdown<String>(
      value: value,
      options: values
          .map((v) => NalaraDropdownOption(value: v.$1, label: v.$2))
          .toList(),
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null ? 'Pilih $label' : null,
      onChanged: onChanged,
    ),
  );
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(22),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toolIntro(
            'Belajar berlanjut,\ndi luar sesi.',
            'Bagikan instruksi dan materi dalam bentuk teks. Siswa dapat mengirim jawaban langsung di NALARA.',
          ),
          toolCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _choice(
                  'Siswa',
                  _student,
                  widget.catalog.students.map((s) => (s.id, s.name)).toList(),
                  widget.activity == null
                      ? (v) => setState(() => _student = v)
                      : null,
                ),
                _choice(
                  'Bidang belajar',
                  _subject,
                  widget.catalog.subjects.map((s) => (s.id, s.name)).toList(),
                  widget.activity == null
                      ? (v) => setState(() => _subject = v)
                      : null,
                ),
                _choice(
                  'Jenis',
                  _kind,
                  const [('task', 'Tugas'), ('material', 'Materi')],
                  widget.activity == null
                      ? (v) => setState(() => _kind = v!)
                      : null,
                ),
                TextFormField(
                  controller: _title,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Judul aktivitas',
                  ),
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Isi judul aktivitas'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _content,
                  minLines: 5,
                  maxLines: 12,
                  maxLength: 10000,
                  decoration: const InputDecoration(
                    labelText: 'Instruksi / materi',
                  ),
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Isi instruksi atau materi'
                      : null,
                ),
                const SizedBox(height: 18),
                if (_kind == 'task') ...[
                  DateTimeField(
                    label: _due == null
                        ? 'Pilih batas pengumpulan (opsional)'
                        : 'Batas pengumpulan',
                    value: _due ?? DateTime.now().add(const Duration(days: 7)),
                    onChanged: (v) => setState(() => _due = v),
                  ),
                  if (_due != null)
                    TextButton(
                      onPressed: () => setState(() => _due = null),
                      child: const Text('Hapus batas waktu'),
                    ),
                  const SizedBox(height: 18),
                ],
                _choice('Status', _status, const [
                  ('draft', 'Simpan draft'),
                  ('published', 'Bagikan sekarang'),
                  ('archived', 'Arsipkan'),
                ], (v) => setState(() => _status = v!)),
                _choice('Akses', _visibility, const [
                  ('student', 'Guru & siswa'),
                  ('shared', 'Guru, siswa & orang tua'),
                ], (v) => setState(() => _visibility = v!)),
                SubmitButton(
                  cubit: _submit,
                  label: 'Simpan aktivitas',
                  onPressed: () async {
                    if (!_form.currentState!.validate() ||
                        _student == null ||
                        _subject == null) {
                      return;
                    }
                    final ok = await _submit.run(
                      () => getIt<TutorToolsRepository>().saveActivity(
                        ActivityDraft(
                          studentId: _student!,
                          subjectId: _subject!,
                          kind: _kind,
                          title: _title.text.trim(),
                          content: _content.text.trim(),
                          status: _status,
                          visibility: _visibility,
                          dueAt: _due,
                        ),
                        id: widget.activity?.id,
                      ),
                    );
                    if (ok && context.mounted) {
                      successMessage(context, 'Aktivitas berhasil disimpan.');
                      finishForm(context, '/teacher/materials');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class FeedbackPage extends StatefulWidget {
  final ActivitySubmission? submission;
  const FeedbackPage({super.key, this.submission});
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late final _text = TextEditingController(text: widget.submission?.feedback);
  final _submit = SubmitCubit();
  @override
  void dispose() {
    _text.dispose();
    _submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NalaraPageScaffold(
    title: 'Tanggapan Guru',
    body: PageBody(
      children: [
        if (widget.submission == null)
          const Text('Buka jawaban dari detail tugas terlebih dahulu.')
        else ...[
          toolIntro(
            'Arahan kecil,\ndampak bermakna.',
            'Berikan tanggapan yang membantu siswa memahami langkah selanjutnya.',
          ),
          toolCard(
            Text(widget.submission!.text, style: const TextStyle(height: 1.7)),
          ),
          TextField(
            controller: _text,
            minLines: 5,
            maxLines: 12,
            maxLength: 5000,
            decoration: const InputDecoration(labelText: 'Tanggapan'),
          ),
          SubmitButton(
            cubit: _submit,
            label: 'Simpan tanggapan',
            onPressed: () async {
              final s = widget.submission!;
              final ok = await _submit.run(
                () => getIt<TutorToolsRepository>().feedback(
                  s.id,
                  _text.text,
                  s.version,
                ),
              );
              if (ok && context.mounted) {
                successMessage(context, 'Tanggapan tersimpan.');
                context.pop();
              }
            },
          ),
        ],
      ],
    ),
  );
}

class TemplatesPage extends StatelessWidget {
  final bool select;
  const TemplatesPage({super.key, this.select = false});
  @override
  Widget build(BuildContext context) => ProToolsGate(
    feature: 'reportTemplates',
    child: PagedListPage<ReportTemplate>(
      title: select ? 'Pilih template' : 'Template laporan',
      empty:
          'Buat format laporan Anda sendiri, lalu gunakan kembali saat menulis laporan.',
      newRoute: '/teacher/templates/new',
      load: (page) => getIt<TutorToolsRepository>().templates(page: page),
      itemBuilder: (context, item, reload) => toolCard(
        InkWell(
          onTap: () async {
            if (select) {
              context.pop(item);
            } else {
              await context.push('/teacher/templates/new', extra: item);
              if (context.mounted) reload();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item.topic.isEmpty ? 'Format laporan pribadi' : item.topic,
                style: const TextStyle(color: NalaraColors.muted, height: 1.6),
              ),
              const SizedBox(height: 12),
              Text(
                select ? 'Gunakan template →' : 'Edit template →',
                style: const TextStyle(
                  color: NalaraColors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class TemplateEditorPage extends StatefulWidget {
  final ReportTemplate? template;
  const TemplateEditorPage({super.key, this.template});
  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  final _form = GlobalKey<FormState>(), _submit = SubmitCubit();
  late final _fields = [
    TextEditingController(text: widget.template?.name),
    TextEditingController(text: widget.template?.topic),
    TextEditingController(text: widget.template?.summary),
    TextEditingController(text: widget.template?.observations),
    TextEditingController(text: widget.template?.difficulties),
    TextEditingController(text: widget.template?.homework),
    TextEditingController(text: widget.template?.recommendation),
  ];
  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    _submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProToolsGate(
    feature: 'reportTemplates',
    child: NalaraPageScaffold(
      title: widget.template == null ? 'Template baru' : 'Edit template',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              toolIntro(
                'Laporan rapi,\ntanpa mengulang.',
                'Tulis kerangka yang dapat dipakai kembali. Sesuaikan isinya dengan keadaan siswa sebelum menerbitkan laporan.',
              ),
              toolCard(
                Column(
                  children: [
                    for (var i = 0; i < _fields.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _fields[i],
                          maxLines: i < 2 ? 1 : 4,
                          maxLength: i == 0
                              ? 100
                              : i == 1
                              ? 200
                              : 3000,
                          validator: i == 0
                              ? (v) => (v?.trim().length ?? 0) < 2
                                    ? 'Isi nama template'
                                    : null
                              : null,
                          decoration: InputDecoration(
                            labelText: const [
                              'Nama template',
                              'Materi / topik',
                              'Ringkasan sesi',
                              'Pengamatan',
                              'Kesulitan',
                              'Latihan lanjutan',
                              'Rekomendasi',
                            ][i],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SubmitButton(
                cubit: _submit,
                label: 'Simpan template',
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final ok = await _submit.run(
                    () => getIt<TutorToolsRepository>().saveTemplate(
                      ReportTemplate(
                        id: widget.template?.id ?? '',
                        name: _fields[0].text.trim(),
                        topic: _fields[1].text,
                        summary: _fields[2].text,
                        observations: _fields[3].text,
                        difficulties: _fields[4].text,
                        homework: _fields[5].text,
                        recommendation: _fields[6].text,
                      ),
                    ),
                  );
                  if (ok && context.mounted) {
                    successMessage(context, 'Template berhasil disimpan.');
                    finishForm(context, '/teacher/templates');
                  }
                },
              ),
              if (widget.template != null)
                TextButton(
                  onPressed: () async {
                    if (!await confirmAction(
                          context,
                          'Hapus template ini? Laporan yang sudah dibuat tetap tersimpan.',
                        ) ||
                        !context.mounted) {
                      return;
                    }
                    final ok = await _submit.run(
                      () => getIt<TutorToolsRepository>().deleteTemplate(
                        widget.template!.id,
                      ),
                    );
                    if (ok && context.mounted) context.pop();
                  },
                  child: const Text(
                    'Hapus template',
                    style: TextStyle(color: Color(0xFFA23535)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProgressAnalyticsPage extends StatefulWidget {
  final String? studentId;
  const ProgressAnalyticsPage({super.key, this.studentId});
  @override
  State<ProgressAnalyticsPage> createState() => _ProgressAnalyticsPageState();
}

class _ProgressAnalyticsPageState extends State<ProgressAnalyticsPage> {
  Future<ProgressAnalytics> _load() =>
      getIt<TutorToolsRepository>().analytics(studentId: widget.studentId);
  @override
  Widget build(BuildContext context) => ProToolsGate(
    feature: 'progressAnalytics',
    child: AsyncPage<ProgressAnalytics>(
      title: 'Analitik perkembangan',
      load: _load,
      builder: (context, value, reload) => PageBody(
        children: [
          toolIntro(
            'Lihat langkah kecil\nyang menjadi kemajuan.',
            'Ringkasan nyata dari target, riwayat perkembangan, dan presensi siswa Anda.',
          ),
          toolCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'PROGRESS KESELURUHAN',
                  style: TextStyle(
                    color: NalaraColors.muted,
                    letterSpacing: 1,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value.progress == null
                      ? 'Belum ada target'
                      : '${value.progress}%',
                  style: const TextStyle(
                    color: NalaraColors.green,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                if (value.progress != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: value.progress! / 100,
                      minHeight: 10,
                      color: NalaraColors.green,
                      backgroundColor: NalaraColors.lightGreen,
                    ),
                  ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    Text('${value.targetCount} target'),
                    Text('${value.completed} selesai'),
                    Text('${value.overdue} terlambat'),
                  ],
                ),
              ],
            ),
          ),
          toolCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kehadiran siswa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  '${value.present} hadir dari ${value.recorded} presensi tercatat',
                  style: const TextStyle(
                    color: NalaraColors.muted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Menurut bidang belajar'),
          for (final subject in value.subjects)
            toolCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('${subject.progress ?? 0}%'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: (subject.progress ?? 0) / 100,
                    minHeight: 8,
                    color: NalaraColors.green,
                    backgroundColor: NalaraColors.lightGreen,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${subject.targetCount} target',
                    style: const TextStyle(
                      fontSize: 12,
                      color: NalaraColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          const SectionTitle('Jejak perkembangan terbaru'),
          if (value.history.isEmpty)
            const Text('Belum ada perubahan progress yang dicatat.'),
          for (final sample in value.history)
            toolCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sample.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${sample.before}% → ${sample.after}%',
                    style: const TextStyle(
                      color: NalaraColors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat(
                      'd MMM yyyy HH:mm',
                      'id_ID',
                    ).format(sample.at.toLocal()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: NalaraColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '${value.note}\nMaksimal 100 perubahan terbaru ditampilkan.',
            style: const TextStyle(
              fontSize: 12,
              color: NalaraColors.muted,
              height: 1.7,
            ),
          ),
        ],
      ),
    ),
  );
}

class TutorPreferencesPage extends StatefulWidget {
  final bool branding;
  const TutorPreferencesPage({super.key, this.branding = false});
  @override
  State<TutorPreferencesPage> createState() => _TutorPreferencesPageState();
}

class _TutorPreferencesPageState extends State<TutorPreferencesPage> {
  Future<TutorPreferences> _load() =>
      getIt<TutorToolsRepository>().preferences(branding: widget.branding);
  @override
  Widget build(BuildContext context) => ProToolsGate(
    feature: widget.branding ? 'branding' : 'notificationPreferences',
    child: AsyncPage<TutorPreferences>(
      title: widget.branding ? 'Identitas laporan' : 'Preferensi notifikasi',
      load: _load,
      builder: (context, p, reload) => _PreferencesEditor(
        key: ValueKey(p),
        preferences: p,
        branding: widget.branding,
      ),
    ),
  );
}

class _PreferencesEditor extends StatefulWidget {
  final TutorPreferences preferences;
  final bool branding;
  const _PreferencesEditor({
    super.key,
    required this.preferences,
    required this.branding,
  });
  @override
  State<_PreferencesEditor> createState() => _PreferencesEditorState();
}

class _PreferencesEditorState extends State<_PreferencesEditor> {
  late final _name = TextEditingController(
        text: widget.preferences.displayName,
      ),
      _tagline = TextEditingController(text: widget.preferences.tagline),
      _footer = TextEditingController(text: widget.preferences.footer);
  late String _color = widget.preferences.accentColor;
  late final List<bool> _values = [
    widget.preferences.reminders,
    widget.preferences.progress,
    widget.preferences.reports,
    widget.preferences.assignments,
  ];
  final _submit = SubmitCubit();
  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _footer.dispose();
    _submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      toolIntro(
        widget.branding
            ? 'Sentuhan Anda,\ndi setiap laporan.'
            : 'Tetap terhubung,\ndengan cara Anda.',
        widget.branding
            ? 'Sesuaikan nama, warna, dan catatan penutup laporan PDF Anda.'
            : 'Pilih notifikasi push yang diterima akun Guru. Pesan tetap tercatat di kotak notifikasi dan tidak mengubah pengiriman kepada siswa atau orang tua.',
      ),
      toolCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.branding) ...[
              TextField(
                controller: _name,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nama tutor / brand',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagline,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Tagline'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _footer,
                maxLength: 300,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan penutup'),
              ),
              const SizedBox(height: 16),
              NalaraDropdown<String>(
                value: _color,
                decoration: const InputDecoration(labelText: 'Warna laporan'),
                options: const [
                  NalaraDropdownOption(value: '#155D49', label: 'Hijau NALARA'),
                  NalaraDropdownOption(value: '#244A6B', label: 'Biru tenang'),
                  NalaraDropdownOption(
                    value: '#66513C',
                    label: 'Cokelat hangat',
                  ),
                  NalaraDropdownOption(value: '#604B72', label: 'Ungu lembut'),
                ],
                onChanged: (v) => setState(() => _color = v!),
              ),
            ] else ...[
              for (var i = 0; i < _values.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          const [
                            'Pengingat jadwal & target H-1',
                            'Perubahan progress',
                            'Laporan belajar',
                            'Tugas & materi',
                          ][i],
                          style: const TextStyle(height: 1.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _values[i],
                        activeTrackColor: NalaraColors.green,
                        onChanged: (v) => setState(() => _values[i] = v),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 24),
            SubmitButton(
              cubit: _submit,
              label: 'Simpan pengaturan',
              onPressed: () async {
                final p = TutorPreferences(
                  displayName: _name.text.trim(),
                  tagline: _tagline.text.trim(),
                  footer: _footer.text.trim(),
                  accentColor: _color,
                  reminders: _values[0],
                  progress: _values[1],
                  reports: _values[2],
                  assignments: _values[3],
                );
                final ok = await _submit.run(
                  () => widget.branding
                      ? getIt<TutorToolsRepository>().saveBranding(p)
                      : getIt<TutorToolsRepository>()
                            .saveNotificationPreferences(p),
                );
                if (ok && context.mounted) {
                  successMessage(context, 'Pengaturan berhasil disimpan.');
                }
              },
            ),
          ],
        ),
      ),
    ],
  );
}

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});
  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  final _submit = SubmitCubit();
  @override
  void dispose() {
    _submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProToolsGate(
    feature: 'dataExport',
    child: NalaraPageScaffold(
      title: 'Export data',
      body: PageBody(
        children: [
          toolIntro(
            'Data Anda,\nselalu dalam jangkauan.',
            'Unduh salinan data pengajaran dalam format CSV untuk arsip dan pengolahan lebih lanjut.',
          ),
          toolCard(
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yang disertakan',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                Text(
                  'Siswa & keluarga • Bidang belajar • Sesi & presensi\nRencana & target • Riwayat progress • Laporan sesi\nTugas & materi • Jawaban siswa • Template laporan',
                  style: TextStyle(height: 1.9),
                ),
                SizedBox(height: 16),
                Text(
                  'Export mencakup data pribadi siswa dan catatan internal. Simpan serta bagikan hanya kepada pihak yang berwenang.',
                  style: TextStyle(
                    color: NalaraColors.muted,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          SubmitButton(
            cubit: _submit,
            label: 'Siapkan & simpan CSV',
            onPressed: () async {
              await _submit.run(() async {
                final files = await getIt<TutorToolsRepository>().exportData();
                if (context.mounted) await shareTutorFiles(context, files);
              });
            },
          ),
        ],
      ),
    ),
  );
}
