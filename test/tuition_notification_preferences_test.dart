import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/tutor_tools/data/tutor_tools_repository_impl.dart';
import 'package:nalara/features/tutor_tools/domain/tutor_tools.dart';
import 'package:nalara/features/tutor_tools/presentation/notification_preference_tile.dart';
import 'package:nalara/features/tuition_fees/data/tuition_model.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy preferences default both tuition reminders on', () async {
    const defaults = TutorPreferences();
    expect(defaults.tuitionTeacherReminders, isTrue);
    expect(defaults.tuitionParentReminders, isTrue);
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {'reminders': false},
              },
            ),
          );
        },
      ),
    );
    final client = ApiClient(dio, TokenStore(const FlutterSecureStorage()));
    final repository = TutorToolsRepositoryImpl(
      TutorToolsRemoteSource(client, client),
    );
    final preferences = await repository.preferences();
    expect(preferences.reminders, isFalse);
    expect(preferences.tuitionTeacherReminders, isTrue);
    expect(preferences.tuitionParentReminders, isTrue);
  });

  test(
    'read and save use two independent flags; branding never overwrites them',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': {
                    'reminders': false,
                    'progress': true,
                    'reports': false,
                    'assignments': true,
                    'tuitionTeacherReminders': false,
                    'tuitionParentReminders': true,
                  },
                },
              ),
            );
          },
        ),
      );
      final client = ApiClient(dio, TokenStore(const FlutterSecureStorage()));
      final repository = TutorToolsRepositoryImpl(
        TutorToolsRemoteSource(client, client),
      );
      final preferences = await repository.preferences();
      expect(preferences.tuitionTeacherReminders, isFalse);
      expect(preferences.tuitionParentReminders, isTrue);
      await repository.saveNotificationPreferences(preferences);
      expect(requests.last.path, ApiConstants.tutorNotificationPreferences);
      expect(requests.last.data, {
        'reminders': false,
        'progress': true,
        'reports': false,
        'assignments': true,
        'tuitionTeacherReminders': false,
        'tuitionParentReminders': true,
      });
      await repository.saveBranding(preferences);
      expect(requests.last.path, ApiConstants.tutorBranding);
      expect(
        (requests.last.data as Map).containsKey('tuitionTeacherReminders'),
        isFalse,
      );
      expect(
        (requests.last.data as Map).containsKey('tuitionParentReminders'),
        isFalse,
      );
    },
  );

  test(
    'tuition overview exposes current reminder settings with legacy defaults',
    () {
      final json = <String, dynamic>{
        'fee': null,
        'teacher': {'name': 'Guru', 'phone': null, 'timezone': 'Asia/Jakarta'},
        'automaticReminders': true,
      };
      expect(TuitionModel(json).toEntity().tuitionTeacherReminders, isTrue);
      final overview = TuitionModel({
        ...json,
        'tuitionTeacherReminders': false,
        'tuitionParentReminders': false,
      }).toEntity();
      expect(overview.tuitionTeacherReminders, isFalse);
      expect(overview.tuitionParentReminders, isFalse);
    },
  );

  testWidgets(
    'themed preference row toggles by text, fits narrow text scaling and disables while saving',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var enabled = true;
      var value = true;
      var changes = 0;
      Future<void> render() => tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(
            body: NotificationPreferenceTile(
              title: 'Pengingat biaya untuk saya',
              description:
                  'Mulai hari jatuh tempo, maksimal sekali sehari per siswa selama belum lunas.',
              value: value,
              onChanged: enabled
                  ? (next) {
                      value = next;
                      changes++;
                    }
                  : null,
            ),
          ),
        ),
      );
      await render();
      expect(find.byType(Switch), findsNothing);
      await tester.tap(find.text('Pengingat biaya untuk saya'));
      expect(value, isFalse);
      expect(changes, 1);
      enabled = false;
      await render();
      await tester.tap(find.text('Pengingat biaya untuk saya'));
      expect(changes, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
