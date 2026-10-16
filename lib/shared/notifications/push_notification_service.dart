import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../../utils/constants.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationTap {
  final String notificationId;
  final String route;
  const NotificationTap({required this.notificationId, required this.route});

  factory NotificationTap.fromMap(Map<String, dynamic> data) => NotificationTap(
    notificationId: data['notificationId']?.toString() ?? '',
    route: data['route']?.toString() ?? '',
  );
}

enum _PushAccountType { teacher, parent, student }

class PushNotificationService {
  final ApiClient teacherApi;
  final ApiClient portalApi;
  final FirebaseMessaging? messaging;
  final FlutterLocalNotificationsPlugin localNotifications;
  final _taps = StreamController<NotificationTap>.broadcast();
  final _pendingReadIds = <String>{};
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  _PushAccountType? _accountType;
  String? _token;
  NotificationTap? _pendingTap;
  bool _initialized = false;

  PushNotificationService({
    required this.teacherApi,
    required this.portalApi,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : messaging = messaging ?? (kIsWeb ? null : FirebaseMessaging.instance),
       localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  Stream<NotificationTap> get taps => _taps.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    final messaging = this.messaging!;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _publish(_decode(payload));
      },
    );
    final androidPlugin = localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'nalara_notifications',
        'Notifikasi Nalara',
        description: 'Pengingat dan informasi aktivitas belajar.',
        importance: Importance.high,
      ),
    );
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForeground,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _publishMessage,
    );
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _publishMessage(initialMessage);
    final launchDetails = await localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) _publish(_decode(payload));
    }
    _tokenSubscription = messaging.onTokenRefresh.listen((token) {
      _token = token;
      unawaited(_register(token));
    });
    _initialized = true;
  }

  Future<void> activateTeacher() => _activate(_PushAccountType.teacher);

  Future<void> activateParent() => _activate(_PushAccountType.parent);

  Future<void> activateStudent() => _activate(_PushAccountType.student);

  Future<void> activatePortal() => activateParent();

  Future<void> _activate(_PushAccountType accountType) async {
    await initialize();
    final messaging = this.messaging;
    if (messaging == null) return;
    _accountType = accountType;
    _token ??= await messaging.getToken();
    if (_token != null) await _register(_token!);
    await _flushPendingReads();
  }

  Future<void> deactivate() async {
    final token = _token;
    final accountType = _accountType;
    _accountType = null;
    if (token == null || accountType == null) return;
    try {
      final api = accountType == _PushAccountType.teacher
          ? teacherApi
          : portalApi;
      final path = switch (accountType) {
        _PushAccountType.teacher => ApiConstants.notificationDevices,
        _PushAccountType.parent => ApiConstants.portalNotificationDevices,
        _PushAccountType.student =>
          ApiConstants.studentPortalNotificationDevices,
      };
      await api.delete(path, data: {'token': token, 'platform': _platform});
    } catch (_) {
      // Session logout must not be blocked by an unavailable push endpoint.
    }
  }

  Future<void> markRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    final accountType = _accountType;
    if (accountType == null) {
      _pendingReadIds.add(notificationId);
      return;
    }
    try {
      final api = accountType == _PushAccountType.teacher
          ? teacherApi
          : portalApi;
      final path = switch (accountType) {
        _PushAccountType.teacher => ApiConstants.notificationRead(
          notificationId,
        ),
        _PushAccountType.parent => ApiConstants.portalNotificationRead(
          notificationId,
        ),
        _PushAccountType.student => ApiConstants.studentPortalNotificationRead(
          notificationId,
        ),
      };
      await api.patch(path, {});
      _pendingReadIds.remove(notificationId);
    } catch (_) {
      // The notification list remains the source of truth if the tap is offline.
    }
  }

  NotificationTap? takePendingTap() {
    final tap = _pendingTap;
    _pendingTap = null;
    return tap;
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  Future<void> _register(String token) async {
    final accountType = _accountType;
    if (accountType == null) return;
    try {
      final api = accountType == _PushAccountType.teacher
          ? teacherApi
          : portalApi;
      final path = switch (accountType) {
        _PushAccountType.teacher => ApiConstants.notificationDevices,
        _PushAccountType.parent => ApiConstants.portalNotificationDevices,
        _PushAccountType.student =>
          ApiConstants.studentPortalNotificationDevices,
      };
      await api.post(path, {'token': token, 'platform': _platform});
    } catch (_) {
      // The next token refresh or authenticated app start retries registration.
    }
  }

  Future<void> _flushPendingReads() async {
    final pending = List<String>.from(_pendingReadIds);
    for (final id in pending) {
      await markRead(id);
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final payload = <String, dynamic>{
      'notificationId': message.data['notificationId']?.toString() ?? '',
      'route': message.data['route']?.toString() ?? '',
    };
    await localNotifications.show(
      message.messageId?.hashCode.abs() ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nalara_notifications',
          'Notifikasi Nalara',
          channelDescription: 'Pengingat dan informasi aktivitas belajar.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(payload),
    );
  }

  void _publishMessage(RemoteMessage message) {
    _publish(NotificationTap.fromMap(Map<String, dynamic>.from(message.data)));
  }

  void _publish(NotificationTap? tap) {
    if (tap == null || tap.notificationId.isEmpty || !_validRoute(tap.route)) {
      return;
    }
    unawaited(markRead(tap.notificationId));
    if (_taps.hasListener) {
      _taps.add(tap);
    } else {
      _pendingTap = tap;
    }
  }

  NotificationTap? _decode(String payload) {
    try {
      final data = jsonDecode(payload);
      return data is Map
          ? NotificationTap.fromMap(Map<String, dynamic>.from(data))
          : null;
    } catch (_) {
      return null;
    }
  }

  bool _validRoute(String route) =>
      route.startsWith('/teacher/') ||
      route.startsWith('/parent/') ||
      route.startsWith('/student/');

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _taps.close();
    await localNotifications.cancelAll();
  }
}
