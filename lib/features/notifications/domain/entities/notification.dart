class TeacherNotification {
  final String id, title, body, route;
  final DateTime createdAt;
  final bool read;
  const TeacherNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.createdAt,
    required this.read,
  });
}
