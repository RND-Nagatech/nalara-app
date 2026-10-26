import '../../../shared/errors/app_failure.dart';
import '../../../shared/network/api_client.dart';

class AvatarsRemoteSource {
  final ApiClient api;
  final bool student;
  final int _session;
  AvatarsRemoteSource(this.api, {required this.student})
    : _session = api.tokens.sessionGeneration;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final result = await api.request(
      method,
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

  Future<Map<String, dynamic>> options() => _request(
    'GET',
    student ? '/portal/student/profile/avatars' : '/me/avatars',
  );
  Future<Map<String, dynamic>> save(String? id) => _request(
    'PATCH',
    student ? '/portal/student/profile/avatar' : '/me/avatar',
    data: {'avatarId': id},
  );
}
