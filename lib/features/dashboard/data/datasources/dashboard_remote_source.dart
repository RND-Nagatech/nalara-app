import '../../../../shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class DashboardRemoteSource {
  final ApiClient api;
  DashboardRemoteSource(this.api);
  Future<Map<String, dynamic>> get() => api.get(ApiConstants.dashboard);
}
