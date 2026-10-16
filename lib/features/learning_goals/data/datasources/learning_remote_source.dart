import '../../../../shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class LearningRemoteSource {
  final ApiClient api;
  LearningRemoteSource(this.api);
  Future<Map<String, dynamic>> plans(int page, String? studentId) => api.get(
    ApiConstants.learningPlans,
    query: {'page': page, 'studentId': ?studentId},
  );
  Future<Map<String, dynamic>> plan(String id) =>
      api.get(ApiConstants.learningPlan(id));
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> data) =>
      api.post(ApiConstants.learningPlans, data);
  Future<Map<String, dynamic>> target(String id) =>
      api.get(ApiConstants.target(id));
  Future<Map<String, dynamic>> addTarget(
    String planId,
    Map<String, dynamic> data,
  ) => api.post(ApiConstants.learningPlanTargets(planId), data);
  Future<void> editTarget(String id, Map<String, dynamic> data) async {
    await api.patch(ApiConstants.target(id), data);
  }

  Future<Map<String, dynamic>> progress(String id, Map<String, dynamic> data) =>
      api.patch(ApiConstants.targetProgress(id), data);
}
