import '../../../../shared/domain/page.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../domain/repositories/student_portal_repository.dart';

class StudentNotificationsRepository implements NotificationsRepository {
  final StudentPortalRepository student;
  const StudentNotificationsRepository(this.student);
  @override
  Future<PageResult<TeacherNotification>> list({int page = 1}) async {
    final result = await student.notifications(page: page);
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
  Future<void> markRead(String id) => student.readNotification(id);
  @override
  Future<void> markAllRead() => student.readAllNotifications();
}
