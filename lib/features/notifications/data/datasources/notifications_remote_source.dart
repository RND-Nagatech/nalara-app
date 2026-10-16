import '../../../../shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class NotificationsRemoteSource {
  final ApiClient api;
  NotificationsRemoteSource(this.api);
  Future<Map<String, dynamic>> list(int page) =>
      api.get(ApiConstants.notifications, query: {'page': page});
  Future<void> read(String id) async {
    await api.patch(ApiConstants.notificationRead(id), {});
  }

  Future<void> readAll() async {
    await api.post(ApiConstants.notificationsReadAll, {});
  }
}
