import 'package:flutter/material.dart';
import '../../../../shared/domain/page.dart';
import '../../../../utils/injector.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../lesson_reports/presentation/pages/reports_pages.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../../domain/usecases/load_student_details.dart';

class StudentReportsPage extends StatelessWidget {
  const StudentReportsPage({super.key});
  static Future<PageResult<LessonReport>> _load(int page, String? _) =>
      getIt<StudentPortalRepository>().reports(page: page);
  @override
  Widget build(BuildContext context) => const ReportsPage(
    loadReports: _load,
    readOnly: true,
    routePrefix: '/student',
    subtitle: 'Laporan perkembangan Anda yang dibagikan Guru.',
  );
}

class StudentReportDetailPage extends StatelessWidget {
  final String id;
  const StudentReportDetailPage({super.key, required this.id});
  static Future<ReportDetailData> _load(String id) =>
      LoadStudentDetails(getIt<StudentPortalRepository>()).report(id);
  @override
  Widget build(BuildContext context) => ReportDetailPage(
    id: id,
    loadReport: _load,
    readOnly: true,
    routePrefix: '/student',
  );
}
