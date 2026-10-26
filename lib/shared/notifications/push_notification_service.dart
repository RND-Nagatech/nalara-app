import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../../utils/constants.dart';
import '../../utils/firebase_web_config.dart';
import '../network/api_client.dart';
import 'web_notification.dart';

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
  bool _permissionGranted = false;
  int _activationGeneration = 0;

  PushNotificationService({
    required this.teacherApi,
    required this.portalApi,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : messaging =
           messaging ??
           (Firebase.apps.isEmpty ? null : FirebaseMessaging.instance),
       localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  Stream<NotificationTap> get taps => _taps.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    final messaging = this.messaging;
    if (messaging == null) {
      _initialized = true;
      return;
    }
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      // Permission is requested only by the custom, user-initiated prompt.
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
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
    }
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForeground,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _publishMessage,
    );
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _publishMessage(initialMessage);
    if (!kIsWeb) {
      final launchDetails = await localNotifications
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null) _publish(_decode(payload));
      }
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

  Future<AuthorizationStatus?> authorizationStatus() async =>
      (await messaging?.getNotificationSettings())?.authorizationStatus;

  /// Start this directly from the user's button event (also required on web).
  /// Do not await storage, initialization or navigation before the SDK call.
  Future<AuthorizationStatus?> requestUserPermission() async {
    final settings = await messaging?.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final status = settings?.authorizationStatus;
    _permissionGranted = _allowed(status);
    return status;
  }

  Future<void> refreshPermissionRegistration() async {
    final accountType = _accountType;
    if (accountType != null) await _activate(accountType);
  }

  bool _allowed(AuthorizationStatus? status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> _activate(_PushAccountType accountType) async {
    final generation = ++_activationGeneration;
    final api = accountType == _PushAccountType.teacher
        ? teacherApi
        : portalApi;
    final sessionGeneration = api.tokens.sessionGeneration;
    await initialize();
    if (generation != _activationGeneration) return;
    final messaging = this.messaging;
    if (messaging == null) return;
    _accountType = accountType;
    try {
      // Silent reads/registration must never cause an OS permission prompt.
      final status = await authorizationStatus();
      if (generation != _activationGeneration) return;
      _permissionGranted = _allowed(status);
      if (!_permissionGranted) return;
      if (kIsWeb) {
        _token ??= await messaging.getToken(
          vapidKey: const FirebaseWebConfig().vapidKey,
          serviceWorkerScriptPath: '/firebase-messaging-sw.js',
        );
      } else {
        _token ??= await messaging.getToken();
      }
    } catch (error) {
      debugPrint('Firebase Messaging tidak tersedia (${error.runtimeType}).');
      return;
    }
    if (generation != _activationGeneration ||
        api.tokens.sessionGeneration != sessionGeneration) {
      return;
    }
    if (_token != null) {
      await _register(_token!, expectedSessionGeneration: sessionGeneration);
    }
    await _flushPendingReads();
  }

  Future<void> deactivate() async {
    _activationGeneration++;
    final token = _token;
    final accountType = _accountType;
    _accountType = null;
    _permissionGranted = false;
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
      await api.delete(
        path,
        data: {'token': token, 'platform': _platform},
        expectedSessionGeneration: api.tokens.sessionGeneration,
      );
    } catch (_) {
      // Session logout must not be blocked by an unavailable push endpoint.
    }
  }

  /// The backend has already revoked the deleted account's device bindings.
  /// Do not call authenticated endpoints using its now-revoked credentials.
  Future<void> forgetDeletedAccount() async {
    _activationGeneration++;
    _accountType = null;
    _permissionGranted = false;
    _pendingTap = null;
    _pendingReadIds.clear();
    await localNotifications.cancelAll();
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

  Future<void> _register(String token, {int? expectedSessionGeneration}) async {
    final accountType = _accountType;
    if (accountType == null || !_permissionGranted) return;
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
      await api.request(
        'POST',
        path,
        data: {'token': token, 'platform': _platform},
        expectedSessionGeneration:
            expectedSessionGeneration ?? api.tokens.sessionGeneration,
      );
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
    if (_accountType == null || !_permissionGranted) return;
    final notification = message.notification;
    if (notification == null) return;
    final payload = <String, dynamic>{
      'notificationId': message.data['notificationId']?.toString() ?? '',
      'route': message.data['route']?.toString() ?? '',
    };
    if (kIsWeb) {
      await showWebNotification(
        title: notification.title ?? 'NALARA',
        body: notification.body,
        route: payload['route'] as String?,
      );
      return;
    }
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
    _activationGeneration++;
    _accountType = null;
    _permissionGranted = false;
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _taps.close();
    await localNotifications.cancelAll();
  }
}
