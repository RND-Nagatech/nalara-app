import '../../../../shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class StudentsRemoteSource {
  final ApiClient api;
  StudentsRemoteSource(this.api);
  Future<Map<String, dynamic>> list(int page, String search, String? status) =>
      api.get(
        ApiConstants.students,
        query: {'page': page, 'limit': 5, 'search': search, 'status': ?status},
      );
  Future<Map<String, dynamic>> get(String id) =>
      api.get(ApiConstants.student(id));
  Future<Map<String, dynamic>> summary(String id) =>
      api.get(ApiConstants.studentSummary(id));
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      api.post(ApiConstants.students, data);
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) =>
      api.patch(ApiConstants.student(id), data);
  Future<Map<String, dynamic>> invite(String id) =>
      api.post(ApiConstants.studentInvitations(id), {});
  Future<Map<String, dynamic>> invitations(String id) =>
      api.get(ApiConstants.studentInvitations(id), query: {'limit': 100});
  Future<void> revoke(String id, String inviteId) async {
    await api.post(ApiConstants.revokeStudentInvitation(id, inviteId), {});
  }

  Future<void> revokeAccess(String id) async {
    await api.post(ApiConstants.revokeStudentAccess(id), {});
  }
}
