import '../../../../shared/network/api_client.dart';
import '../../../../utils/constants.dart';

class ParentPortalRemoteSource {
  final ApiClient api;
  ParentPortalRemoteSource(this.api);

  Future<Map<String, dynamic>> dashboard({String? studentId}) =>
      api.get(ApiConstants.portalDashboard, query: {'studentId': ?studentId});
  Future<Map<String, dynamic>> students(
    int page,
    String search,
    String? status,
  ) => api.get(
    ApiConstants.portalStudents,
    query: {'page': page, 'limit': 5, 'search': search, 'status': ?status},
  );
  Future<Map<String, dynamic>> student(String id) =>
      api.get(ApiConstants.portalStudent(id));
  Future<Map<String, dynamic>> sessions(Map<String, dynamic> query) =>
      api.get(ApiConstants.portalSessions, query: query);
  Future<Map<String, dynamic>> session(String id) =>
      api.get(ApiConstants.portalSession(id));
  Future<Map<String, dynamic>> sessionOverview(String id) =>
      api.get('${ApiConstants.portalSession(id)}/overview');
  Future<Map<String, dynamic>> plans(Map<String, dynamic> query) =>
      api.get(ApiConstants.portalPlans, query: query);
  Future<Map<String, dynamic>> plan(String id) =>
      api.get(ApiConstants.portalPlan(id));
  Future<Map<String, dynamic>> target(String id) =>
      api.get('/portal/targets/${Uri.encodeComponent(id)}');
  Future<Map<String, dynamic>> reports(Map<String, dynamic> query) =>
      api.get(ApiConstants.portalReports, query: query);
  Future<Map<String, dynamic>> report(String id) =>
      api.get(ApiConstants.portalReport(id));
  Future<Map<String, dynamic>> notifications(int page) => api.get(
    ApiConstants.portalNotifications,
    query: {'page': page, 'limit': 30},
  );
  Future<void> readNotification(String id) async {
    await api.patch(ApiConstants.portalNotificationRead(id), {});
  }

  Future<void> readAllNotifications() async {
    await api.post(ApiConstants.portalNotificationsReadAll, {});
  }

  Future<Map<String, dynamic>> availability(
    String sessionId,
    DateTime from,
    DateTime to,
  ) => api.get(
    ApiConstants.portalAvailability,
    query: {
      'sessionId': sessionId,
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    },
  );
  Future<void> requestReschedule(
    String sessionId,
    DateTime startAt,
    DateTime endAt,
    String reason,
  ) async {
    await api.post(ApiConstants.portalRescheduleRequests, {
      'sessionId': sessionId,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'reason': reason.trim(),
    });
  }

  Future<Map<String, dynamic>> rescheduleRequests(int page) => api.get(
    ApiConstants.portalRescheduleRequests,
    query: {'page': page, 'limit': 30},
  );

  Future<void> cancelRescheduleRequest(String id) async {
    await api.delete(
      '${ApiConstants.portalRescheduleRequests}/${Uri.encodeComponent(id)}',
    );
  }

  Future<void> respondRescheduleRequest(String id, String action) async {
    await api.patch(
      '${ApiConstants.portalRescheduleRequests}/${Uri.encodeComponent(id)}',
      {'action': action},
    );
  }
}
