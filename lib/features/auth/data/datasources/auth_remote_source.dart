import '../../../../shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class AuthRemoteSource {
  final ApiClient api;
  AuthRemoteSource(this.api);
  Future<Map<String, dynamic>> login(Map<String, dynamic> fields) =>
      api.post(ApiConstants.login, fields, authenticated: false);
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) => api.post(
    ApiConstants.googleLogin,
    {'idToken': idToken},
    authenticated: false,
  );
  Future<Map<String, dynamic>> register(Map<String, dynamic> fields) =>
      api.post(ApiConstants.register, fields, authenticated: false);
  Future<Map<String, dynamic>> forgotPassword(Map<String, dynamic> fields) =>
      api.post(ApiConstants.forgotPassword, fields, authenticated: false);
  Future<Map<String, dynamic>> verifyResetOtp(Map<String, dynamic> fields) =>
      api.post(ApiConstants.verifyResetOtp, fields, authenticated: false);
  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> fields) =>
      api.post(ApiConstants.resetPassword, fields, authenticated: false);
  Future<Map<String, dynamic>> me() => api.get(ApiConstants.me);
  Future<void> logout() async {
    await api.post(ApiConstants.logout, {});
  }
}
