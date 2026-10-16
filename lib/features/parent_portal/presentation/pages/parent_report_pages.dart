import 'package:flutter/material.dart';

import '../../../../shared/domain/page.dart';
import '../../../../utils/injector.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../lesson_reports/presentation/pages/reports_pages.dart';
import '../../domain/repositories/parent_portal_repository.dart';

class ParentSharedReportsPage extends StatelessWidget {
  final String? studentId;
  const ParentSharedReportsPage({super.key, this.studentId});

  static Future<PageResult<LessonReport>> _loadReports(
    int page,
    String? studentId,
  ) =>
      getIt<ParentPortalRepository>().reports(page: page, studentId: studentId);

  @override
  Widget build(BuildContext context) => ReportsPage(
    studentId: studentId,
    loadReports: _loadReports,
    readOnly: true,
    routePrefix: '/parent',
  );
}

class ParentSharedReportDetailPage extends StatelessWidget {
  final String id;
  const ParentSharedReportDetailPage({super.key, required this.id});

  static Future<ReportDetailData> _loadReport(String id) async {
    final parent = getIt<ParentPortalRepository>();
    final report = await parent.report(id);
    final lesson = await parent.session(report.sessionId);
    final detail = await parent.student(report.studentId);
    return (report: report, lesson: lesson, studentName: detail.student.name);
  }

  @override
  Widget build(BuildContext context) => ReportDetailPage(
    id: id,
    loadReport: _loadReport,
    readOnly: true,
    routePrefix: '/parent',
  );
}
