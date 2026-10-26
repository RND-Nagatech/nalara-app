import '../../../shared/network/api_client.dart';
import '../../../utils/constants.dart';

class StudentGroupsRemoteSource {
  final ApiClient api;
  StudentGroupsRemoteSource(this.api);
  Future<Map<String, dynamic>> list(int page, int limit, String search) =>
      api.get(
        ApiConstants.studentGroups,
        query: {'page': page, 'limit': limit, 'search': search},
      );
  Future<Map<String, dynamic>> get(String id) =>
      api.get(ApiConstants.studentGroup(id));
  Future<void> save(String? id, Map<String, dynamic> data) async {
    if (id == null) {
      await api.post(ApiConstants.studentGroups, data);
    } else {
      await api.patch(ApiConstants.studentGroup(id), data);
    }
  }

  Future<void> remove(String id, int version) async {
    await api.delete(ApiConstants.studentGroup(id), data: {'version': version});
  }
}
