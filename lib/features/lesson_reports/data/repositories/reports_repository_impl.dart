import '../../../../shared/domain/page.dart';
import '../../../../shared/domain/teaching_catalog_changes.dart';
import '../../../../shared/errors/app_failure.dart';
import '../../domain/entities/lesson_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_source.dart';
import '../models/report_model.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteSource remote;
  final TeachingCatalogChanges? changes;
  ReportsRepositoryImpl(this.remote, {this.changes});
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
  Future<int> draftCount() async {
    final json = await remote.list({'page': 1, 'limit': 1, 'status': 'draft'});
    final total = json['total'];
    if (total is! int || total < 0) {
      throw const AppFailure('Jumlah draf laporan belum dapat dimuat.');
    }
    return total;
  }

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
  Future<LessonReport> create(String sessionId, ReportDraft draft) async {
    final report = ReportModel(
      await remote.create(sessionId, fields(draft)),
    ).toEntity();
    changes?.notifyChanged();
    return report;
  }

  @override
  Future<List<LessonReport>> createBatch(
    String sessionId,
    ReportDraft draft, {
    required Map<String, List<String>> targetsBySession,
    required bool publish,
  }) async {
    final content = fields(draft)..remove('targetIds');
    final json = await remote.createBatch(sessionId, {
      ...content,
      'status': publish ? 'published' : 'draft',
      'entries': targetsBySession.entries
          .map((entry) => {'sessionId': entry.key, 'targetIds': entry.value})
          .toList(),
    });
    final reports = (json['items'] as List)
        .map((row) => ReportModel(Map<String, dynamic>.from(row)).toEntity())
        .toList();
    changes?.notifyChanged();
    return reports;
  }

  @override
  Future<void> update(LessonReport report, ReportDraft draft) async {
    await remote.update(report.sessionId, report.id, fields(draft));
    changes?.notifyChanged();
  }

  @override
  Future<void> publish(LessonReport report) async {
    await remote.publish(report.sessionId, report.id);
    changes?.notifyChanged();
  }
}
