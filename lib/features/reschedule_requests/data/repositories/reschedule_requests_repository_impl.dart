import '../../../../shared/domain/page.dart';
import '../../domain/entities/reschedule_request.dart';
import '../../domain/repositories/reschedule_requests_repository.dart';
import '../datasources/reschedule_requests_remote_source.dart';
import '../models/reschedule_request_model.dart';

class RescheduleRequestsRepositoryImpl implements RescheduleRequestsRepository {
  final RescheduleRequestsRemoteSource remote;
  RescheduleRequestsRepositoryImpl(this.remote);
  @override
  Future<PageResult<RescheduleRequest>> list({
    int page = 1,
    String? status,
  }) async {
    final json = await remote.list(page, status);
    return PageResult(
      items: List.unmodifiable(
        (json['items'] as List).map(
          (row) =>
              RescheduleRequestModel(Map<String, dynamic>.from(row)).toEntity(),
        ),
      ),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }

  @override
  Future<List<RescheduleSlot>> availability(
    String id, {
    required DateTime from,
    required DateTime to,
  }) async {
    final json = await remote.availability(id, from, to);
    return List.unmodifiable(
      (json['slots'] as List).map(
        (row) => RescheduleSlotModel(Map<String, dynamic>.from(row)).toEntity(),
      ),
    );
  }

  @override
  Future<void> review(
    String id,
    String status, {
    String? note,
    DateTime? proposedStartAt,
    DateTime? proposedEndAt,
  }) => remote.review(
    id,
    status,
    note: note,
    proposedStartAt: proposedStartAt,
    proposedEndAt: proposedEndAt,
  );
}
