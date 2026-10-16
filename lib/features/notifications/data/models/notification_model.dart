import '../../domain/entities/notification.dart';

class NotificationModel {
  final Map<String, dynamic> json;
  NotificationModel(this.json);
  TeacherNotification toEntity() => TeacherNotification(
    id: json['_id'],
    title: json['title'],
    body: json['body'],
    route: json['route'],
    createdAt: DateTime.parse(json['createdAt']),
    read: json['readAt'] != null,
  );
}
