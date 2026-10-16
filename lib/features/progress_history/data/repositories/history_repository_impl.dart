import '../../../../shared/domain/page.dart';
import '../../domain/entities/progress_record.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_source.dart';
import '../models/history_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteSource remote;
  HistoryRepositoryImpl(this.remote);
  @override
  Future<PageResult<ProgressRecord>> list(
    String targetId, {
    int page = 1,
  }) async {
    final json = await remote.list(targetId, page);
    return PageResult(
      items: (json['items'] as List)
          .map((e) => HistoryModel(Map<String, dynamic>.from(e)).toEntity())
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
    );
  }
}
