import '../../../shared/network/api_client.dart';
import '../../../utils/constants.dart';

class TuitionRemoteSource {
  final ApiClient api;
  final bool parent;
  TuitionRemoteSource(this.api, {this.parent = false});
  String _path(String id) =>
      parent ? ApiConstants.parentTuitionFee(id) : ApiConstants.tuitionFee(id);
  Future<Map<String, dynamic>> get(String id) => api.get(_path(id));
  Future<void> save(String id, Map<String, dynamic> data) async {
    if (parent) throw StateError('Akses Orang Tua hanya untuk melihat.');
    await api.patch(_path(id), data);
  }
}
