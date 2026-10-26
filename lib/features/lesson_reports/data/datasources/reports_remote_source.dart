import '../../../../shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class ReportsRemoteSource {
  final ApiClient api;
  ReportsRemoteSource(this.api);
  Future<Map<String, dynamic>> list(Map<String, dynamic> query) =>
      api.get(ApiConstants.reports, query: query);
  Future<Map<String, dynamic>> get(String id) =>
      api.get(ApiConstants.report(id));
  Future<Map<String, dynamic>> create(
    String sessionId,
    Map<String, dynamic> data,
  ) => api.post(ApiConstants.sessionReports(sessionId), data);
  Future<Map<String, dynamic>> createBatch(
    String sessionId,
    Map<String, dynamic> data,
  ) => api.post('${ApiConstants.sessionReports(sessionId)}/batch', data);
  Future<void> update(
    String sessionId,
    String id,
    Map<String, dynamic> data,
  ) async {
    await api.patch(ApiConstants.sessionReport(sessionId, id), data);
  }

  Future<void> publish(String sessionId, String id) async {
    await api.post(ApiConstants.publishSessionReport(sessionId, id), {});
  }
}
