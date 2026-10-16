import '../../../../shared/domain/page.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../domain/repositories/parent_portal_repository.dart';

/// Adapts the parent-authorized inbox to the common notification presentation.
class ParentNotificationsRepository implements NotificationsRepository {
  final ParentPortalRepository parent;
  ParentNotificationsRepository(this.parent);
  @override
  Future<PageResult<TeacherNotification>> list({int page = 1}) async {
    final result = await parent.notifications(page: page);
    return PageResult(
      items: result.items
          .map(
            (item) => TeacherNotification(
              id: item.id,
              title: item.title,
              body: item.body,
              route: item.route,
              createdAt: item.createdAt,
              read: item.read,
            ),
          )
          .toList(),
      total: result.total,
      page: result.page,
      limit: result.limit,
    );
  }

  @override
  Future<void> markRead(String id) => parent.markNotificationRead(id);
  @override
  Future<void> markAllRead() => parent.markAllNotificationsRead();
}
