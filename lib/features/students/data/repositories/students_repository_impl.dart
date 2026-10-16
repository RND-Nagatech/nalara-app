import '../../../../shared/domain/page.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_summary.dart';
import '../../domain/repositories/students_repository.dart';
import '../datasources/students_remote_source.dart';
import '../models/student_model.dart';
import '../models/student_summary_model.dart';

class StudentsRepositoryImpl implements StudentsRepository {
  final StudentsRemoteSource remote;
  StudentsRepositoryImpl(this.remote);
  Map<String, dynamic> fields(StudentDraft d) => {
    'name': d.name.trim(),
    'grade': d.grade.trim(),
    'notes': d.notes.trim(),
    if (d.familyId != null || d.clearFamily) 'familyId': d.familyId,
  };
  @override
  Future<PageResult<Student>> list({
    int page = 1,
    String search = '',
    String? status,
  }) async {
    final json = await remote.list(page, search, status);
    return PageResult(
      items: (json['items'] as List)
          .map((e) => StudentModel(Map<String, dynamic>.from(e)).toEntity())
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
    );
  }

  @override
  Future<Student> get(String id) async =>
      StudentModel(await remote.get(id)).toEntity();
  @override
  Future<StudentSummary> summary(String id) async =>
      StudentSummaryModel(await remote.summary(id)).toEntity();
  @override
  Future<Student> create(StudentDraft draft) async =>
      StudentModel(await remote.create(fields(draft))).toEntity();
  @override
  Future<Student> update(String id, StudentDraft draft) async =>
      StudentModel(await remote.update(id, fields(draft))).toEntity();
  @override
  Future<void> archive(String id) async {
    await remote.update(id, {'status': 'archived'});
  }

  @override
  Future<ParentInvitation> invite(String studentId) async =>
      InvitationModel(await remote.invite(studentId)).toEntity();
  @override
  Future<List<ParentInvitation>> invitations(String studentId) async =>
      ((await remote.invitations(studentId))['items'] as List)
          .map((e) => InvitationModel(Map<String, dynamic>.from(e)).toEntity())
          .toList();
  @override
  Future<void> revoke(String studentId, String invitationId) =>
      remote.revoke(studentId, invitationId);
  @override
  Future<void> revokeAccess(String studentId) => remote.revokeAccess(studentId);
}
