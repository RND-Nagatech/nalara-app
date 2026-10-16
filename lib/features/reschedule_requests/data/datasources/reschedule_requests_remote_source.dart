import '../../../../shared/network/api_client.dart';
import '../../../../utils/constants.dart';

class RescheduleRequestsRemoteSource {
  final ApiClient api;
  RescheduleRequestsRemoteSource(this.api);
  Future<Map<String, dynamic>> list(int page, String? status) => api.get(
    ApiConstants.rescheduleRequests,
    query: {'page': page, 'limit': 30, 'status': ?status},
  );
  Future<Map<String, dynamic>> availability(
    String id,
    DateTime from,
    DateTime to,
  ) => api.get(
    '${ApiConstants.teacherRescheduleRequest(Uri.encodeComponent(id))}/availability',
    query: {
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    },
  );

  Future<void> review(
    String id,
    String status, {
    String? note,
    DateTime? proposedStartAt,
    DateTime? proposedEndAt,
  }) async {
    await api
        .patch(ApiConstants.teacherRescheduleRequest(Uri.encodeComponent(id)), {
          'status': status,
          'note': ?note,
          'proposedStartAt': ?proposedStartAt?.toUtc().toIso8601String(),
          'proposedEndAt': ?proposedEndAt?.toUtc().toIso8601String(),
        });
  }
}
