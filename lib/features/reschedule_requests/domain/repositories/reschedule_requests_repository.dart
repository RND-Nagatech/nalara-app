import '../../../../shared/domain/page.dart';
import '../entities/reschedule_request.dart';

abstract class RescheduleRequestsRepository {
  Future<PageResult<RescheduleRequest>> list({int page = 1, String? status});
  Future<List<RescheduleSlot>> availability(
    String id, {
    required DateTime from,
    required DateTime to,
  });
  Future<void> review(
    String id,
    String status, {
    String? note,
    DateTime? proposedStartAt,
    DateTime? proposedEndAt,
  });
}
