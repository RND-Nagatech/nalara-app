import 'dart:convert';
import '../../../shared/domain/page.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/errors/app_failure.dart';
import '../../../utils/constants.dart';
import '../domain/tutor_tools.dart';

class TutorToolsRemoteSource {
  final ApiClient teacher, portal;
  TutorToolsRemoteSource(this.teacher, this.portal);
  Future<Map<String, dynamic>> get(
    String path, {
    bool parent = false,
    Map<String, dynamic>? query,
  }) => (parent ? portal : teacher).get(path, query: query);
}

Map<String, dynamic> _map(dynamic value) =>
    Map<String, dynamic>.from(value as Map);
ActivitySubmission _submission(Map<String, dynamic> j) => ActivitySubmission(
  id: j['_id'] as String,
  text: j['text'] as String,
  feedback: j['feedback'] as String? ?? '',
  version: (j['version'] as num).toInt(),
  reviewedAt: DateTime.tryParse(j['reviewedAt'] as String? ?? ''),
);
LearningActivity _activity(Map<String, dynamic> j) => LearningActivity(
  id: j['_id'] as String,
  studentId: j['studentId'] as String,
  subjectId: j['subjectId'] as String,
  studentName: j['studentName'] as String? ?? '',
  subjectName: j['subjectName'] as String? ?? '',
  kind: j['kind'] as String,
  title: j['title'] as String,
  content: j['content'] as String,
  status: j['status'] as String,
  visibility: j['visibility'] as String,
  dueAt: DateTime.tryParse(j['dueAt'] as String? ?? ''),
  submissions: (j['submissions'] as List? ?? [])
      .map((v) => _submission(_map(v)))
      .toList(),
);
ReportTemplate _template(Map<String, dynamic> j) => ReportTemplate(
  id: j['_id'] as String,
  name: j['name'] as String,
  topic: j['topic'] as String? ?? '',
  summary: j['summary'] as String? ?? '',
  observations: j['observations'] as String? ?? '',
  difficulties: j['difficulties'] as String? ?? '',
  homework: j['homework'] as String? ?? '',
  recommendation: j['recommendation'] as String? ?? '',
);
TutorExport _file(Map<String, dynamic> j) => TutorExport(
  filename: j['filename'] as String,
  mimeType: j['mimeType'] as String,
  bytes: base64Decode(j['contentBase64'] as String),
);

class TutorToolsRepositoryImpl implements TutorToolsRepository {
  final TutorToolsRemoteSource source;
  TutorToolsRepositoryImpl(this.source);
  PageResult<T> _page<T>(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) parse,
  ) => PageResult(
    items: (j['items'] as List).map((v) => parse(_map(v))).toList(),
    total: (j['total'] as num).toInt(),
    page: (j['page'] as num).toInt(),
    limit: (j['limit'] as num).toInt(),
  );
  @override
  Future<PageResult<LearningActivity>> activities({
    int page = 1,
    bool portal = false,
  }) async => _page(
    await source.get(
      portal ? ApiConstants.portalAssignments : ApiConstants.assignments,
      parent: portal,
      query: {'page': page, 'limit': 10},
    ),
    _activity,
  );
  @override
  Future<LearningActivity> activity(String id, {bool portal = false}) async =>
      _activity(
        await source.get(
          portal
              ? ApiConstants.portalAssignment(id)
              : ApiConstants.assignment(id),
          parent: portal,
        ),
      );
  @override
  Future<void> saveActivity(ActivityDraft d, {String? id}) async {
    if (d.studentIds.isEmpty ||
        d.studentIds.length > 100 ||
        d.studentIds.toSet().length != d.studentIds.length) {
      throw const AppFailure('Pilih 1–100 siswa yang berbeda.');
    }
    if (id != null && d.studentIds.length != 1) {
      throw const AppFailure(
        'Penerima aktivitas yang sudah dibuat tidak dapat diubah menjadi grup.',
      );
    }
    final data = {
      if (id == null)
        'studentIds': d.studentIds
      else
        'studentId': d.studentIds.single,
      'subjectId': d.subjectId,
      'kind': d.kind,
      'title': d.title,
      'content': d.content,
      'status': d.status,
      'visibility': d.visibility,
      if (d.dueAt != null) 'dueAt': d.dueAt!.toUtc().toIso8601String(),
    };
    if (id == null) {
      await source.teacher.post(ApiConstants.assignmentBatch, data);
    } else {
      await source.teacher.patch(ApiConstants.assignment(id), data);
    }
  }

  @override
  Future<void> submit(String id, String text, int version) async {
    await source.portal.post(ApiConstants.assignmentSubmission(id), {
      'text': text,
      'version': version,
    });
  }

  @override
  Future<void> feedback(String id, String text, int version) async {
    await source.teacher.patch(ApiConstants.submissionFeedback(id), {
      'feedback': text,
      'version': version,
    });
  }

  @override
  Future<PageResult<ReportTemplate>> templates({int page = 1}) async => _page(
    await source.get(
      ApiConstants.reportTemplates,
      query: {'page': page, 'limit': 20},
    ),
    _template,
  );
  @override
  Future<void> saveTemplate(ReportTemplate t) async {
    final data = {
      'name': t.name,
      'topic': t.topic,
      'summary': t.summary,
      'observations': t.observations,
      'difficulties': t.difficulties,
      'homework': t.homework,
      'recommendation': t.recommendation,
    };
    if (t.id.isEmpty) {
      await source.teacher.post(ApiConstants.reportTemplates, data);
    } else {
      await source.teacher.patch(ApiConstants.reportTemplate(t.id), data);
    }
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await source.teacher.delete(ApiConstants.reportTemplate(id));
  }

  @override
  Future<TutorPreferences> preferences({bool branding = false}) async {
    final j = await source.get(
      branding
          ? ApiConstants.tutorBranding
          : ApiConstants.tutorNotificationPreferences,
    );
    return TutorPreferences(
      displayName: j['displayName'] as String? ?? '',
      tagline: j['tagline'] as String? ?? '',
      footer: j['footer'] as String? ?? '',
      accentColor: j['accentColor'] as String? ?? '#155D49',
      logoVersion: j['logoVersion'] as String?,
      reminders: j['reminders'] != false,
      progress: j['progress'] != false,
      reports: j['reports'] != false,
      assignments: j['assignments'] != false,
      tuitionTeacherReminders: j['tuitionTeacherReminders'] != false,
      tuitionParentReminders: j['tuitionParentReminders'] != false,
    );
  }

  @override
  Future<void> saveBranding(TutorPreferences p) async {
    await source.teacher.patch(ApiConstants.tutorBranding, {
      'displayName': p.displayName,
      'tagline': p.tagline,
      'footer': p.footer,
      'accentColor': p.accentColor,
    });
  }

  @override
  Future<void> saveNotificationPreferences(TutorPreferences p) async {
    await source.teacher.patch(ApiConstants.tutorNotificationPreferences, {
      'reminders': p.reminders,
      'progress': p.progress,
      'reports': p.reports,
      'assignments': p.assignments,
      'tuitionTeacherReminders': p.tuitionTeacherReminders,
      'tuitionParentReminders': p.tuitionParentReminders,
    });
  }

  @override
  Future<ProgressAnalytics> analytics({String? studentId}) async {
    final j = await source.get(
      ApiConstants.progressAnalytics,
      query: {'studentId': ?studentId},
    );
    final a = _map(j['attendance']);
    return ProgressAnalytics(
      progress: (j['progress'] as num?)?.toInt(),
      targetCount: (j['targetCount'] as num).toInt(),
      completed: (j['completed'] as num).toInt(),
      overdue: (j['overdue'] as num).toInt(),
      present: (a['present'] as num).toInt(),
      recorded: (a['recorded'] as num).toInt(),
      note: j['periodNote'] as String,
      subjects: (j['bySubject'] as List).map((v) {
        final s = _map(v);
        return SubjectProgress(
          s['name'] as String,
          (s['targetCount'] as num).toInt(),
          (s['progress'] as num?)?.toInt(),
        );
      }).toList(),
      history: (j['history'] as List).map((v) {
        final h = _map(v);
        return ProgressSample(
          h['title'] as String,
          (h['before'] as num).toInt(),
          (h['after'] as num).toInt(),
          DateTime.parse(h['createdAt'] as String),
        );
      }).toList(),
    );
  }

  @override
  Future<TutorExport> reportPdf(String id) async =>
      _file(await source.get(ApiConstants.reportPdf(id)));
  @override
  Future<List<TutorExport>> exportData() async {
    final j = await source.get(ApiConstants.exportData);
    return (j['files'] as List).map((v) => _file(_map(v))).toList();
  }
}
