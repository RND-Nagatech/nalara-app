import '../../../shared/domain/page.dart';

class LearningActivity {
  final String id,
      studentId,
      subjectId,
      studentName,
      subjectName,
      kind,
      title,
      content,
      status,
      visibility;
  final DateTime? dueAt;
  final List<ActivitySubmission> submissions;
  const LearningActivity({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.studentName,
    required this.subjectName,
    required this.kind,
    required this.title,
    required this.content,
    required this.status,
    required this.visibility,
    this.dueAt,
    this.submissions = const [],
  });
}

class ActivityDraft {
  final String studentId, subjectId, kind, title, content, status, visibility;
  final DateTime? dueAt;
  const ActivityDraft({
    required this.studentId,
    required this.subjectId,
    required this.kind,
    required this.title,
    required this.content,
    required this.status,
    required this.visibility,
    this.dueAt,
  });
}

class ActivitySubmission {
  final String id, text, feedback;
  final int version;
  final DateTime? reviewedAt;
  const ActivitySubmission({
    required this.id,
    required this.text,
    required this.feedback,
    required this.version,
    this.reviewedAt,
  });
}

class ReportTemplate {
  final String id,
      name,
      topic,
      summary,
      observations,
      difficulties,
      homework,
      recommendation;
  const ReportTemplate({
    this.id = '',
    required this.name,
    this.topic = '',
    this.summary = '',
    this.observations = '',
    this.difficulties = '',
    this.homework = '',
    this.recommendation = '',
  });
}

class TutorPreferences {
  final String displayName, tagline, footer, accentColor;
  final bool reminders, progress, reports, assignments;
  const TutorPreferences({
    this.displayName = '',
    this.tagline = '',
    this.footer = '',
    this.accentColor = '#155D49',
    this.reminders = true,
    this.progress = true,
    this.reports = true,
    this.assignments = true,
  });
}

class SubjectProgress {
  final String name;
  final int targetCount;
  final int? progress;
  const SubjectProgress(this.name, this.targetCount, this.progress);
}

class ProgressSample {
  final String title;
  final int before, after;
  final DateTime at;
  const ProgressSample(this.title, this.before, this.after, this.at);
}

class ProgressAnalytics {
  final int? progress;
  final int targetCount, completed, overdue, present, recorded;
  final String note;
  final List<SubjectProgress> subjects;
  final List<ProgressSample> history;
  const ProgressAnalytics({
    required this.progress,
    required this.targetCount,
    required this.completed,
    required this.overdue,
    required this.present,
    required this.recorded,
    required this.note,
    required this.subjects,
    required this.history,
  });
}

class TutorExport {
  final String filename, mimeType;
  final List<int> bytes;
  const TutorExport({
    required this.filename,
    required this.mimeType,
    required this.bytes,
  });
}

abstract interface class TutorToolsRepository {
  Future<PageResult<LearningActivity>> activities({
    int page = 1,
    bool portal = false,
  });
  Future<LearningActivity> activity(String id, {bool portal = false});
  Future<void> saveActivity(ActivityDraft draft, {String? id});
  Future<void> submit(String id, String text, int version);
  Future<void> feedback(String id, String text, int version);
  Future<PageResult<ReportTemplate>> templates({int page = 1});
  Future<void> saveTemplate(ReportTemplate template);
  Future<void> deleteTemplate(String id);
  Future<TutorPreferences> preferences({bool branding = false});
  Future<void> saveBranding(TutorPreferences preferences);
  Future<void> saveNotificationPreferences(TutorPreferences preferences);
  Future<ProgressAnalytics> analytics({String? studentId});
  Future<TutorExport> reportPdf(String id);
  Future<List<TutorExport>> exportData();
}
