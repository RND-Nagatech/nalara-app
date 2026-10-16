import 'dart:async';
import 'package:nalara/features/notifications/domain/entities/notification.dart';
import 'package:nalara/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:nalara/shared/domain/page.dart';

TeacherNotification notificationFixture(
  String id, {
  bool read = false,
  String route = '/teacher/reports/report-1',
  String? title,
  String? body,
}) => TeacherNotification(
  id: id,
  title: title ?? 'Laporan $id',
  body: body ?? 'Laporan belajar siap dibaca.',
  route: route,
  createdAt: DateTime.utc(2026, 10, 15, 8, 18),
  read: read,
);

class NotificationsFake implements NotificationsRepository {
  List<TeacherNotification> records = [];
  int limit = 20;
  final pages = <int>[];
  final reads = <String>[];
  Object? listError, readError;
  Completer<void>? readGate;
  Future<PageResult<TeacherNotification>> Function(int)? respond;

  @override
  Future<PageResult<TeacherNotification>> list({int page = 1}) async {
    pages.add(page);
    if (respond != null) return respond!(page);
    if (listError != null) throw listError!;
    return PageResult(
      items: records.skip((page - 1) * limit).take(limit).toList(),
      total: records.length,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<void> markRead(String id) async {
    reads.add(id);
    if (readGate != null) await readGate!.future;
    if (readError != null) throw readError!;
    records = records
        .map(
          (item) => item.id == id
              ? TeacherNotification(
                  id: item.id,
                  title: item.title,
                  body: item.body,
                  route: item.route,
                  createdAt: item.createdAt,
                  read: true,
                )
              : item,
        )
        .toList();
  }

  @override
  Future<void> markAllRead() async {
    records = records
        .map(
          (item) => TeacherNotification(
            id: item.id,
            title: item.title,
            body: item.body,
            route: item.route,
            createdAt: item.createdAt,
            read: true,
          ),
        )
        .toList();
  }
}
