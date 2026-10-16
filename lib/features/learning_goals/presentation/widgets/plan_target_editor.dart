import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_dropdown.dart';
import '../../../../utils/validators.dart';
import '../../domain/entities/learning_goal.dart';
import 'plan_form_style.dart';

/// UI-only controllers: the API still owns target policy/progress/aggregation.
class PlanTargetFields {
  final int id;
  final anchor = GlobalKey();
  final title = TextEditingController(),
      description = TextEditingController(),
      criteria = TextEditingController();
  String priority = 'normal';
  PlanTargetFields(this.id, [LearningTarget? source]) {
    if (source != null) {
      title.text = source.title;
      description.text = source.description;
      criteria.text = source.successCriteria;
      priority = source.priority;
    }
  }
  TargetDraft get draft => TargetDraft(
    title: title.text,
    description: description.text,
    successCriteria: criteria.text,
    priority: priority,
  );
  void dispose() {
    title.dispose();
    description.dispose();
    criteria.dispose();
  }
}

class PlanTargetEditor extends StatelessWidget {
  final PlanTargetFields fields;
  final int number;
  final VoidCallback? onRemove;
  final bool enabled;
  const PlanTargetEditor({
    super.key,
    required this.fields,
    required this.number,
    this.onRemove,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => Container(
    key: fields.anchor,
    margin: const EdgeInsets.only(top: 14),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE1EAE3)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: PlanFormStyle.paleGreen.withValues(alpha: .7),
          padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text('Target $number', style: PlanFormStyle.label),
              ),
              TextButton(
                key: ValueKey('plan-target-remove-${fields.id}'),
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE43D3D),
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _input(
                'title',
                'Judul target',
                'Masukkan judul target',
                fields.title,
                200,
                requiredField: true,
              ),
              _input(
                'description',
                'Deskripsi',
                'Tambahkan deskripsi target',
                fields.description,
                3000,
                multiline: true,
              ),
              _input(
                'criteria',
                'Indikator keberhasilan',
                'Contoh: mampu mengerjakan 10 soal tanpa bantuan',
                fields.criteria,
                1000,
              ),
              const PlanFormLabel('Prioritas'),
              NalaraDropdown<String>(
                key: ValueKey('plan-target-priority-${fields.id}'),
                menuTitle: 'Prioritas target $number',
                searchHint: 'Cari prioritas...',
                value: fields.priority,
                enabled: enabled,
                options: ['low', 'normal', 'high']
                    .map(
                      (value) => NalaraDropdownOption(
                        value: value,
                        label: statusLabel(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => fields.priority = value!,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _input(
    String id,
    String label,
    String hint,
    TextEditingController controller,
    int maxLength, {
    bool requiredField = false,
    bool multiline = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlanFormLabel(
          label,
          requiredField: requiredField,
          optional: !requiredField,
        ),
        TextFormField(
          key: ValueKey('plan-target-$id-${fields.id}'),
          controller: controller,
          enabled: enabled,
          validator: requiredField ? Validators.name : null,
          maxLength: maxLength,
          minLines: multiline ? 2 : 1,
          maxLines: multiline ? 4 : 1,
          keyboardType: multiline
              ? TextInputType.multiline
              : TextInputType.text,
          textCapitalization: TextCapitalization.sentences,
          style: PlanFormStyle.supporting.copyWith(color: PlanFormStyle.ink),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    ),
  );
}
