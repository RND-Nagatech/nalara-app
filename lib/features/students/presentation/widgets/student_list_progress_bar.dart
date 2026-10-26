import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_progress_bar.dart';
import 'students_style.dart';

class StudentListProgressBar extends StatelessWidget {
  final int? progress;
  final String emptyLabel;

  const StudentListProgressBar({
    super.key,
    required this.progress,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) => NalaraProgressBar(
    progress: progress,
    semanticsLabel: 'Progres minggu ini',
    emptyLabel: emptyLabel,
    fillColor: StudentsStyle.green,
    backgroundColor: StudentsStyle.listProgressTrack,
    accentColor: null,
    height: StudentsStyle.listProgressHeight,
  );
}
