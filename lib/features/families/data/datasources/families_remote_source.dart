import '../../../../shared/network/api_client.dart';
import '../../../../utils/constants.dart';

class FamiliesRemoteSource {
  final ApiClient api;
  FamiliesRemoteSource(this.api);
  Future<Map<String, dynamic>> list(int page, String search) => api.get(
    ApiConstants.families,
    query: {'page': page, 'limit': 100, 'search': search},
  );
  Future<Map<String, dynamic>> get(String id) =>
      api.get(ApiConstants.family(id));
  Future<Map<String, dynamic>> create(Map<String, dynamic> fields) =>
      api.post(ApiConstants.families, fields);
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> fields) =>
      api.patch(ApiConstants.family(id), fields);
  Future<Map<String, dynamic>> createCode(String id) =>
      api.post(ApiConstants.familyInvitations(id), {});
  Future<Map<String, dynamic>> invitations(String id) =>
      api.get(ApiConstants.familyInvitations(id), query: {'limit': 100});
  Future<void> revokeCode(String id, String invitationId) async {
    await api.post(ApiConstants.revokeFamilyInvitation(id, invitationId), {});
  }

  Future<void> revokeAccess(String id) async {
    await api.post(ApiConstants.revokeFamilyAccess(id), {});
  }
}
