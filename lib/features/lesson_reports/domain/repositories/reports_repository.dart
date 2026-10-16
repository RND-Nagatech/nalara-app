import '../../../../shared/domain/page.dart';
import '../entities/lesson_report.dart';

abstract class ReportsRepository {
  Future<PageResult<LessonReport>> list({
    int page = 1,
    String? studentId,
    String? status,
    String? sessionId,
  });
  Future<LessonReport> get(String id);
  Future<LessonReport> create(String sessionId, ReportDraft draft);
  Future<void> update(LessonReport report, ReportDraft draft);
  Future<void> publish(LessonReport report);
}
