import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> showWebNotification({
  required String title,
  String? body,
  String? route,
}) async {
  if (web.Notification.permission != 'granted') return;

  final notification = web.Notification(
    title,
    web.NotificationOptions(
      body: body ?? '',
      icon: '/icons/Icon-192.png?v=nalara-1',
      tag: 'nalara-${DateTime.now().millisecondsSinceEpoch}',
    ),
  );
  if (route == null || route.isEmpty) return;

  notification.onclick = ((web.Event _) {
    final target = '${web.window.location.origin}/#$route';
    web.window.location.href = target;
    notification.close();
  }).toJS;
}
