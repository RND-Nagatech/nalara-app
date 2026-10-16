import '../../../../shared/domain/page.dart';
import '../entities/progress_record.dart';

abstract class HistoryRepository {
  Future<PageResult<ProgressRecord>> list(String targetId, {int page = 1});
}
