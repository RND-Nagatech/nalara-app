import '../../../../shared/network/api_client.dart';
import '../../../../utils/constants.dart';
import '../../domain/entities/app_role.dart';

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

  Future<void> deleteAccount(AppRole role) async {
    await api.delete(
      role == AppRole.student
          ? ApiConstants.studentPortalAccountDeletion
          : ApiConstants.portalAccountDeletion,
    );
  }
}
