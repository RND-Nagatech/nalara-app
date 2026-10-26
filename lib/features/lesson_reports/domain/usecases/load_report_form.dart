import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../learning_goals/domain/repositories/learning_repository.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../schedules/domain/repositories/schedules_repository.dart';
import '../entities/lesson_report.dart';
import '../repositories/reports_repository.dart';

class ReportRecipient {
  final String sessionId, studentId, studentName;
  final List<LearningTarget> targets;
  ReportRecipient({
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required List<LearningTarget> targets,
  }) : targets = List.unmodifiable(targets);
}

class ReportFormData {
  final Lesson lesson;
  final LessonReport? report;
  final List<ReportRecipient> recipients;
  ReportFormData({
    required this.lesson,
    required this.report,
    required List<ReportRecipient> recipients,
  }) : recipients = List.unmodifiable(recipients);
}

/// Resolve the selected child occurrences, never the group's representative
/// student, and keep evaluated targets scoped to each recipient.
class LoadReportForm {
  final ReportsRepository reports;
  final SchedulesRepository schedules;
  final LearningRepository learning;
  const LoadReportForm(this.reports, this.schedules, this.learning);

  Future<ReportFormData> call({
    String? sessionId,
    String? reportId,
    List<String> sessionIds = const [],
  }) async {
    final report = reportId == null ? null : await reports.get(reportId);
    final anchor = report?.sessionId ?? sessionId;
    if (anchor == null) throw StateError('Pilih sesi terlebih dahulu.');
    final ids = report != null
        ? [report.sessionId]
        : sessionIds.isEmpty
        ? [anchor]
        : sessionIds;
    if (ids.isEmpty || ids.length > 100 || ids.toSet().length != ids.length) {
      throw StateError('Pilih 1–100 siswa yang berbeda.');
    }
    final lesson = await schedules.session(anchor);
    final members = lesson.participants.isEmpty
        ? [
            SessionParticipant(
              sessionId: lesson.id,
              studentId: lesson.studentId,
              studentName: lesson.studentName,
              attendance: lesson.attendance,
              status: lesson.status,
            ),
          ]
        : lesson.participants;
    final recipients = <ReportRecipient>[];
    for (final id in ids) {
      final matches = members.where((member) => member.sessionId == id);
      if (matches.isEmpty) {
        throw StateError('Siswa harus berasal dari pertemuan yang sama.');
      }
      final member = matches.single;
      if (member.status == 'cancelled' && report == null) {
        throw StateError('Sesi siswa dibatalkan. Muat ulang sesi.');
      }
      final targets = <LearningTarget>[];
      var page = 1;
      while (true) {
        final plans = await learning.plans(
          page: page,
          studentId: member.studentId,
        );
        for (final plan in plans.items.where(
          (plan) => plan.subjectId == lesson.subjectId,
        )) {
          targets.addAll((await learning.plan(plan.id)).targets);
        }
        if (!plans.hasNext) break;
        page++;
      }
      recipients.add(
        ReportRecipient(
          sessionId: id,
          studentId: member.studentId,
          studentName: member.studentName,
          targets: targets,
        ),
      );
    }
    return ReportFormData(
      lesson: lesson,
      report: report,
      recipients: recipients,
    );
  }
}
