import '../../../../shared/domain/page.dart';
import '../entities/student.dart';
import '../entities/student_summary.dart';

abstract class StudentsRepository {
  Future<PageResult<Student>> list({
    int page = 1,
    String search = '',
    String? status,
  });
  Future<Student> get(String id);
  Future<StudentSummary> summary(String id);
  Future<Student> create(StudentDraft draft);
  Future<Student> update(String id, StudentDraft draft);
  Future<void> archive(String id);
  Future<ParentInvitation> invite(String studentId);
  Future<List<ParentInvitation>> invitations(String studentId);
  Future<void> revoke(String studentId, String invitationId);
  Future<void> revokeAccess(String studentId);
}
