import '../../../shared/network/api_client.dart';
import '../../../utils/constants.dart';

class TeachingGuideRemoteSource {
  final ApiClient api;
  const TeachingGuideRemoteSource(this.api);

  Future<Map<String, dynamic>> get() => api.get(ApiConstants.teachingGuide);
  Future<Map<String, dynamic>> setDismissed(bool value) =>
      api.patch(ApiConstants.teachingGuidePreferences, {'dismissed': value});
}
