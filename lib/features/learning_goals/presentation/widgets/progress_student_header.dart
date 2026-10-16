import 'package:flutter/material.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/progress_form_data.dart';
import 'progress_form_style.dart';

class ProgressStudentHeader extends StatelessWidget {
  final ProgressFormData data;
  const ProgressStudentHeader({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final name = data.student.name.trim();
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    final initials = parts
        .map((part) => part.characters.first)
        .join()
        .toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 0, 28),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: ProgressFormStyle.paleGreen,
                child: Text(
                  initials.isEmpty ? '—' : initials,
                  key: const ValueKey('progress-student-initials'),
                  style: ProgressFormStyle.label.copyWith(
                    fontSize: 20,
                    color: ProgressFormStyle.green,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: ProgressFormStyle.label.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        data.student.grade,
                        data.plan.subjectName,
                      ].where((text) => text.trim().isNotEmpty).join(' · '),
                      style: ProgressFormStyle.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text(
          data.target.title,
          style: ProgressFormStyle.label.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Periode target · ${DateTimeUtils.date(data.plan.startAt)} – ${DateTimeUtils.date(data.plan.endAt)}',
          style: ProgressFormStyle.body,
        ),
      ],
    );
  }
}
