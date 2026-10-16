import '../../../../shared/network/api_client.dart';
import '../../../../utils/constants.dart';

class StudentPortalRemoteSource {
  final ApiClient api;
  StudentPortalRemoteSource(this.api);
  Future<Map<String, dynamic>> dashboard() =>
      api.get(ApiConstants.studentPortalDashboard);
  Future<Map<String, dynamic>> profile() =>
      api.get(ApiConstants.studentPortalProfile);
  Future<Map<String, dynamic>> sessions(Map<String, dynamic> query) =>
      api.get(ApiConstants.studentPortalSessions, query: query);
  Future<Map<String, dynamic>> session(String id) =>
      api.get(ApiConstants.studentPortalSession(id));
  Future<Map<String, dynamic>> sessionOverview(String id) =>
      api.get('${ApiConstants.studentPortalSession(id)}/overview');
  Future<Map<String, dynamic>> plans(Map<String, dynamic> query) =>
      api.get(ApiConstants.studentPortalPlans, query: query);
  Future<Map<String, dynamic>> plan(String id) =>
      api.get(ApiConstants.studentPortalPlan(id));
  Future<Map<String, dynamic>> target(String id) =>
      api.get(ApiConstants.studentPortalTarget(id));
  Future<Map<String, dynamic>> reports(Map<String, dynamic> query) =>
      api.get(ApiConstants.studentPortalReports, query: query);
  Future<Map<String, dynamic>> report(String id) =>
      api.get(ApiConstants.studentPortalReport(id));
  Future<Map<String, dynamic>> notifications(int page) => api.get(
    ApiConstants.studentPortalNotifications,
    query: {'page': page, 'limit': 30},
  );
  Future<void> readNotification(String id) async =>
      api.patch(ApiConstants.studentPortalNotificationRead(id), {});
  Future<void> readAllNotifications() async =>
      api.post(ApiConstants.studentPortalNotificationsReadAll, {});
}
