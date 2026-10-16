import '../../../../shared/domain/page.dart';
import '../../domain/entities/lesson_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_source.dart';
import '../models/report_model.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteSource remote;
  ReportsRepositoryImpl(this.remote);
  Map<String, dynamic> fields(ReportDraft d) => {
    'topic': d.topic.trim(),
    'summary': d.summary.trim(),
    'observations': d.observations.trim(),
    'difficulties': d.difficulties.trim(),
    'homework': d.homework.trim(),
    'recommendation': d.recommendation.trim(),
    'visibility': d.visibility,
    'targetIds': d.targetIds,
  };
  @override
  Future<PageResult<LessonReport>> list({
    int page = 1,
    String? studentId,
    String? status,
    String? sessionId,
  }) async {
    final json = await remote.list({
      'page': page,
      'studentId': ?studentId,
      'status': ?status,
      'sessionId': ?sessionId,
    });
    return PageResult(
      items: (json['items'] as List)
          .map((e) => ReportModel(Map<String, dynamic>.from(e)).toEntity())
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
    );
  }

  @override
  Future<LessonReport> get(String id) async =>
      ReportModel(await remote.get(id)).toEntity();
  @override
  Future<LessonReport> create(String sessionId, ReportDraft draft) async =>
      ReportModel(await remote.create(sessionId, fields(draft))).toEntity();
  @override
  Future<void> update(LessonReport report, ReportDraft draft) =>
      remote.update(report.sessionId, report.id, fields(draft));
  @override
  Future<void> publish(LessonReport report) =>
      remote.publish(report.sessionId, report.id);
}
