import '../../../../shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class SubjectsRemoteSource {
  final ApiClient api;
  SubjectsRemoteSource(this.api);
  Future<Map<String, dynamic>> list(int page) =>
      api.get(ApiConstants.subjects, query: {'page': page, 'limit': 100});
  Future<Map<String, dynamic>> create(String name) =>
      api.post(ApiConstants.subjects, {'name': name.trim()});
  Future<Map<String, dynamic>> get(String id) =>
      api.get(ApiConstants.subject(id));
  Future<Map<String, dynamic>> update(String id, String name) =>
      api.patch(ApiConstants.subject(id), {'name': name.trim()});
}
