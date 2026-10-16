import 'package:flutter/material.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../domain/entities/student.dart';
import 'student_list_progress_bar.dart';
import 'students_style.dart';

class StudentListCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  const StudentListCard({
    super.key,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = student.learningSummary;
    final progress = summary?.weeklyProgress;
    final subtitle = [
      student.grade.isEmpty ? 'Kelas belum diisi' : student.grade,
      if (summary != null) ...summary.subjectNames,
    ].join(' · ');
    final progressMessage = summary == null
        ? 'Progres belum tersedia'
        : progress == null
        ? 'Belum ada target minggu ini'
        : 'Progres minggu ini';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 14, 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(context),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            student.name,
                            style: const TextStyle(
                              fontFamily: 'NalaraInter',
                              fontSize: 17,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: StudentsStyle.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 25,
                            color: StudentsStyle.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: StudentsStyle.body.copyWith(
                        color: const Color(0xFF697066),
                      ),
                    ),
                    if (student.status != 'active') ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECE8DF),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            statusLabel(student.status),
                            style: StudentsStyle.body.copyWith(
                              fontSize: 11,
                              color: const Color(0xFF62685F),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          progressMessage,
                          style: StudentsStyle.body.copyWith(
                            fontSize: 12.5,
                            color: const Color(0xFF697066),
                          ),
                        ),
                        if (progress != null)
                          Text(
                            '$progress%',
                            key: ValueKey('student-progress-${student.id}'),
                            style: StudentsStyle.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: progress < 50
                                  ? const Color(0xFFA75B24)
                                  : StudentsStyle.green,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    StudentListProgressBar(
                      key: ValueKey('student-progress-bar-${student.id}'),
                      progress: progress,
                      emptyLabel: progressMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    final words = student.name.trim().split(RegExp(r'\s+'));
    final initials = words.first.isEmpty
        ? ''
        : '${words.first.characters.first}${words.length > 1 ? words.last.characters.first : ''}'
              .toUpperCase();
    final scale = MediaQuery.textScalerOf(context).scale(20) / 20;
    final size = 56.0 * scale.clamp(1, 1.5);
    return ExcludeSemantics(
      child: Container(
        key: ValueKey('student-avatar-${student.id}'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE4ECDD),
          border: Border.all(color: const Color(0xFFF2F3E9), width: 3),
        ),
        alignment: Alignment.center,
        child: initials.isEmpty
            ? const Icon(Icons.person_outline, color: StudentsStyle.green)
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontFamily: 'NalaraLora',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: StudentsStyle.green,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
