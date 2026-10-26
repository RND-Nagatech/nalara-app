import '../../../../shared/domain/page.dart';
import '../entities/lesson_report.dart';

abstract class ReportsRepository {
  /// Canonical workspace total, independent of the currently loaded list.
  Future<int> draftCount();
  Future<PageResult<LessonReport>> list({
    int page = 1,
    String? studentId,
    String? status,
    String? sessionId,
  });
  Future<LessonReport> get(String id);
  Future<LessonReport> create(String sessionId, ReportDraft draft);
  Future<List<LessonReport>> createBatch(
    String sessionId,
    ReportDraft draft, {
    required Map<String, List<String>> targetsBySession,
    required bool publish,
  });
  Future<void> update(LessonReport report, ReportDraft draft);
  Future<void> publish(LessonReport report);
}
