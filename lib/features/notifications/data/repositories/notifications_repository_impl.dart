import '../../../../shared/domain/page.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_source.dart';
import '../models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteSource remote;
  NotificationsRepositoryImpl(this.remote);
  @override
  Future<PageResult<TeacherNotification>> list({int page = 1}) async {
    final json = await remote.list(page);
    return PageResult(
      items: (json['items'] as List)
          .map(
            (e) => NotificationModel(Map<String, dynamic>.from(e)).toEntity(),
          )
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
    );
  }

  @override
  Future<void> markRead(String id) => remote.read(id);

  @override
  Future<void> markAllRead() => remote.readAll();
}
