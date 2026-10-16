import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_card_style.dart';
import '../../domain/entities/subject.dart';
import 'subject_form_style.dart';

class SubjectListCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onEdit;

  const SubjectListCard({
    super.key,
    required this.subject,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DecoratedBox(
      decoration: NalaraCardStyle.decoration(),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    subject.name,
                    style: const TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: SubjectFormStyle.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  key: ValueKey('subject-edit-${subject.id}'),
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: SubjectFormStyle.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    minimumSize: const Size(48, 44),
                    textStyle: const TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
