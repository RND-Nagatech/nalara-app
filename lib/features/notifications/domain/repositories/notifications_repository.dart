import '../../../../shared/domain/page.dart';
import '../entities/notification.dart';

abstract class NotificationsRepository {
  Future<PageResult<TeacherNotification>> list({int page = 1});
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
