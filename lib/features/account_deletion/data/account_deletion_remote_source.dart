import '../../../shared/network/api_client.dart';
import '../../../utils/constants.dart';

class AccountDeletionRemoteSource {
  final ApiClient api;
  const AccountDeletionRemoteSource(this.api);
  Future<Map<String, dynamic>> summary() =>
      api.get(ApiConstants.accountDeletion);
  Future<Map<String, dynamic>> remove({
    String? password,
    String? idToken,
    int? expectedSessionGeneration,
  }) => api.delete(
    ApiConstants.accountDeletion,
    expectedSessionGeneration: expectedSessionGeneration,
    data: {
      'confirmation': 'HAPUS AKUN',
      'acknowledged': true,
      'password': ?password,
      'idToken': ?idToken,
    },
  );
}
