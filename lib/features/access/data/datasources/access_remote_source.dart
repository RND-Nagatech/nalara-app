import '../../../../shared/network/api_client.dart';
import '../../../../utils/constants.dart';

class AccessRemoteSource {
  final ApiClient api;
  AccessRemoteSource(this.api);
  Future<Map<String, dynamic>> me() => api.get(ApiConstants.portalMe);
  Future<Map<String, dynamic>> redeem(String code, String audience) => api.post(
    ApiConstants.referralRedeem,
    {'token': code.trim(), 'audience': audience},
    authenticated: false,
  );
  Future<void> logout(String refreshToken) async {
    await api.post(ApiConstants.portalLogout, {
      'refreshToken': refreshToken,
    }, authenticated: false);
  }
}
