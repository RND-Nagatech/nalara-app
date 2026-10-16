import '../../../learning_goals/domain/entities/learning_goal.dart';
import '../../../lesson_reports/domain/entities/lesson_report.dart';
import '../../../schedules/domain/entities/lesson.dart';
import 'student.dart';
import 'student_summary.dart';
import '../../../../shared/domain/page.dart';

class StudentOverview {
  final Student student;
  final StudentSummary summary;
  final PageResult<LearningPlan> planPage;
  final PageResult<Lesson> lessonPage;
  final PageResult<LessonReport> reportPage;
  List<LearningPlan> get plans => planPage.items;
  List<Lesson> get lessons => lessonPage.items;
  List<LessonReport> get reports => reportPage.items;
  final List<ParentInvitation> invitations;
  final StudentFamilySummary? family;
  StudentOverview({
    required this.student,
    required this.summary,
    required PageResult<LearningPlan> plans,
    required PageResult<Lesson> lessons,
    required PageResult<LessonReport> reports,
    required List<ParentInvitation> invitations,
    this.family,
  }) : planPage = _snapshot(plans),
       lessonPage = _snapshot(lessons),
       reportPage = _snapshot(reports),
       invitations = List.unmodifiable(invitations);

  static PageResult<T> _snapshot<T>(PageResult<T> page) => PageResult(
    items: List.unmodifiable(page.items),
    total: page.total,
    page: page.page,
    limit: page.limit,
  );
}

class StudentFamilySummary {
  final String id, name, parentName, parentPhone;
  const StudentFamilySummary({
    required this.id,
    required this.name,
    required this.parentName,
    required this.parentPhone,
  });
}
