import '../../../../shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class HistoryRemoteSource {
  final ApiClient api;
  HistoryRemoteSource(this.api);
  Future<Map<String, dynamic>> list(String id, int page) =>
      api.get(ApiConstants.targetHistory(id), query: {'page': page});
}
