import '../../../../shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class SchedulesRemoteSource {
  final ApiClient api;
  SchedulesRemoteSource(this.api);
  Future<Map<String, dynamic>> sessions(Map<String, dynamic> query) =>
      api.get(ApiConstants.sessions, query: query);
  Future<Map<String, dynamic>> session(String id) =>
      api.get(ApiConstants.session(id));
  Future<Map<String, dynamic>> schedule(String id) =>
      api.get(ApiConstants.schedule(id));
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      api.post(ApiConstants.schedules, data);
  Future<void> updateSession(String id, Map<String, dynamic> data) async {
    await api.patch(ApiConstants.session(id), data);
  }

  Future<void> cancelSeries(String id) async {
    await api.patch(ApiConstants.schedule(id), {'status': 'cancelled'});
  }

  Future<void> attendance(String id, String status) async {
    await api.patch(ApiConstants.sessionAttendance(id), {'attendance': status});
  }
}
