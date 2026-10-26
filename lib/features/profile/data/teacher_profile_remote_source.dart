import '../../../shared/errors/app_failure.dart';
import '../../../shared/network/api_client.dart';

class TeacherProfileRemoteSource {
  final ApiClient api;
  final int _session;
  TeacherProfileRemoteSource(this.api)
    : _session = api.tokens.sessionGeneration;

  Future<Map<String, dynamic>> updatePhone(String phone) async {
    return _update('/me/phone', {'phone': phone});
  }

  Future<Map<String, dynamic>> updateTimezone(String timezone) =>
      _update('/me/timezone', {'timezone': timezone});

  Future<Map<String, dynamic>> _update(
    String path,
    Map<String, String> data,
  ) async {
    final result = await api.request(
      'PATCH',
      path,
      data: data,
      expectedSessionGeneration: _session,
    );
    if (api.tokens.sessionGeneration != _session) {
      throw const AppFailure(
        'Sesi akun berubah. Silakan buka kembali profil akun Anda.',
        code: 'SESSION_CHANGED',
      );
    }
    return Map<String, dynamic>.from(result);
  }
}
