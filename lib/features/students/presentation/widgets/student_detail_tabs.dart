import 'package:flutter/material.dart';
import 'student_detail_style.dart';

const studentDetailTabLabels = [
  'Ringkasan',
  'Target & bidang belajar',
  'Riwayat sesi',
  'Laporan belajar',
  'Orang Tua & keluarga',
  'Kode referral',
];

class StudentDetailTabs extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final double height;
  final List<String> labels;
  StudentDetailTabs({
    required this.controller,
    required this.height,
    this.labels = studentDetailTabLabels,
  });
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: StudentDetailStyle.cream,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF0EFE7),
          borderRadius: BorderRadius.circular(22),
        ),
        child: TabBar(
          key: const ValueKey('student-detail-tabs'),
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: StudentDetailStyle.green,
          unselectedLabelColor: StudentDetailStyle.muted,
          labelStyle: StudentDetailStyle.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
          indicatorColor: StudentDetailStyle.green,
          dividerColor: Colors.transparent,
          tabs: [
            for (var index = 0; index < labels.length; index++)
              Tab(
                key: ValueKey('student-tab-$index'),
                child: Text(labels[index], softWrap: false),
              ),
          ],
        ),
      ),
    ),
  );
  @override
  bool shouldRebuild(covariant StudentDetailTabs oldDelegate) =>
      oldDelegate.controller != controller ||
      oldDelegate.height != height ||
      oldDelegate.labels != labels;
}
