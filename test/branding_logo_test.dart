import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/tutor_tools/data/branding_logo_repository_impl.dart';
import 'package:nalara/features/tutor_tools/domain/branding_logo.dart';
import 'package:nalara/features/tutor_tools/presentation/branding_logo_card.dart';
import 'package:nalara/features/tutor_tools/presentation/branding_logo_cubit.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/shared/widgets/nalara_dialog.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/constants.dart';
import 'package:nalara/utils/injector.dart';

const png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACXBIWXMAAAPoAAAD6AG1e1JrAAAADUlEQVQImWMQiXL8DwAC5AGvKoGphQAAAABJRU5ErkJggg==';
BrandingLogo logo([String version = 'v1']) =>
    BrandingLogo(version: version, bytes: base64Decode(png));
PickedBrandingLogo picked() =>
    PickedBrandingLogo(mimeType: 'image/png', bytes: base64Decode(png));
Map<String, dynamic> response() => {
  'logo': {'version': 'v1', 'mimeType': 'image/png', 'contentBase64': png},
};

class LogoRepositoryFake implements BrandingLogoRepository {
  BrandingLogo? value = logo();
  Object? readError, writeError;
  Completer<BrandingLogo?>? readGate;
  Completer<BrandingLogo>? uploadGate;
  int reads = 0, uploads = 0, removals = 0;
  @override
  Future<BrandingLogo?> read() async {
    reads++;
    if (readError != null) throw readError!;
    return readGate?.future ?? value;
  }

  @override
  Future<BrandingLogo> upload(PickedBrandingLogo file) async {
    uploads++;
    if (writeError != null) throw writeError!;
    value = await (uploadGate?.future ?? Future.value(logo('v2')));
    return value!;
  }

  @override
  Future<void> remove() async {
    removals++;
    if (writeError != null) throw writeError!;
    value = null;
  }
}

class LogoPickerFake implements BrandingLogoPicker {
  PickedBrandingLogo? value = picked();
  Completer<PickedBrandingLogo?>? gate;
  int calls = 0;
  @override
  Future<PickedBrandingLogo?> pick() async {
    calls++;
    return gate?.future ?? value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'strict logo model rejects malformed responses and returns immutable bytes',
    () {
      expect(decodeBrandingLogo({'logo': null}), isNull);
      final saved = decodeBrandingLogo(response())!;
      expect(saved.version, 'v1');
      expect(() => saved.bytes.clear(), throwsUnsupportedError);
      for (final invalid in [
        <String, dynamic>{},
        {'logo': true},
        {
          'logo': {
            'version': 'v1',
            'mimeType': 'image/jpeg',
            'contentBase64': png,
          },
        },
        {
          'logo': {
            'version': '',
            'mimeType': 'image/png',
            'contentBase64': png,
          },
        },
        {
          'logo': {
            'version': 'v1',
            'mimeType': 'image/png',
            'contentBase64': 'not-base64',
          },
        },
      ]) {
        expect(() => decodeBrandingLogo(invalid), throwsA(isA<AppFailure>()));
      }
    },
  );

  test(
    'repository uses central private endpoint and a single multipart file; removal confirms null',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final tokens = TokenStore(const FlutterSecureStorage())
        ..accessToken = 'teacher-access';
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': options.method == 'DELETE'
                      ? {'logo': null}
                      : response(),
                },
              ),
            );
          },
        ),
      );
      final repository = BrandingLogoRepositoryImpl(ApiClient(dio, tokens));
      expect((await repository.read())!.version, 'v1');
      await repository.upload(picked());
      await repository.remove();
      expect(
        requests.map((request) => request.path),
        everyElement(ApiConstants.tutorBrandingLogo),
      );
      expect(requests.map((request) => request.method), [
        'GET',
        'POST',
        'DELETE',
      ]);
      final form = requests[1].data as FormData;
      expect(form.fields, isEmpty);
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'logo.png');
      expect(form.files.single.value.contentType.toString(), 'image/png');
      expect(requests[1].headers['Authorization'], 'Bearer teacher-access');
    },
  );

  test(
    '401 upload retry recreates finalized multipart body after refreshing the same session',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final tokens = TokenStore(const FlutterSecureStorage());
      await tokens.save('old-access', 'old-refresh', persist: true);
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final bodies = <FormData>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (options.path == ApiConstants.refreshToken) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'data': {
                      'accessToken': 'new-access',
                      'refreshToken': 'new-refresh',
                    },
                  },
                ),
              );
              return;
            }
            final form = options.data as FormData;
            bodies.add(form);
            await form.finalize().drain<void>();
            if (bodies.length == 1) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(requestOptions: options, statusCode: 401),
                ),
              );
            } else {
              expect(options.headers['Authorization'], 'Bearer new-access');
              handler.resolve(
                Response(requestOptions: options, data: {'data': response()}),
              );
            }
          },
        ),
      );
      final repository = BrandingLogoRepositoryImpl(ApiClient(dio, tokens));
      expect((await repository.upload(picked())).version, 'v1');
      expect(bodies.length, 2);
      expect(identical(bodies.first, bodies.last), isFalse);
    },
  );

  test(
    'session-bound repository never uploads a previously selected logo into a new account',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final tokens = TokenStore(const FlutterSecureStorage());
      await tokens.save('owner', 'refresh', persist: true);
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      var sends = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sends++;
            handler.resolve(
              Response(requestOptions: options, data: {'data': response()}),
            );
          },
        ),
      );
      final repository = BrandingLogoRepositoryImpl(ApiClient(dio, tokens));
      await tokens.save('other-account', 'other-refresh', persist: true);
      await expectLater(
        repository.upload(picked()),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.code,
            'code',
            'SESSION_CHANGED',
          ),
        ),
      );
      expect(sends, 0);
      expect(tokens.accessToken, 'other-account');
    },
  );

  test(
    'picker cancellation, hidden route and disposed editor never upload',
    () async {
      final repository = LogoRepositoryFake();
      final picker = LogoPickerFake()..value = null;
      final cubit = BrandingLogoCubit(repository, picker);
      await cubit.load();
      expect(await cubit.choose(isCurrent: () => true), isFalse);
      expect(repository.uploads, 0);
      expect(cubit.state.logo!.version, 'v1');
      picker.gate = Completer<PickedBrandingLogo?>();
      var current = true;
      final pending = cubit.choose(isCurrent: () => current);
      current = false;
      picker.gate!.complete(picked());
      expect(await pending, isFalse);
      expect(repository.uploads, 0);
      picker.gate = Completer<PickedBrandingLogo?>();
      final closing = cubit.choose(isCurrent: () => true);
      await cubit.close();
      picker.gate!.complete(picked());
      expect(await closing, isFalse);
      expect(repository.uploads, 0);
    },
  );

  test(
    'failed reads are not empty success; replacement/removal errors retain the saved preview',
    () async {
      final repository = LogoRepositoryFake();
      final cubit = BrandingLogoCubit(repository, LogoPickerFake());
      await cubit.load();
      repository.readError = const AppFailure('Penyimpanan tidak tersedia.');
      await cubit.load();
      expect(cubit.state.logo!.version, 'v1');
      expect(cubit.state.error, 'Penyimpanan tidak tersedia.');
      repository.writeError = const AppFailure('Logo melebihi batas.');
      expect(await cubit.choose(isCurrent: () => true), isFalse);
      expect(cubit.state.logo!.version, 'v1');
      expect(await cubit.remove(), isFalse);
      expect(cubit.state.logo!.version, 'v1');
      repository.writeError = null;
      expect(await cubit.remove(), isTrue);
      expect(cubit.state.logo, isNull);
      await cubit.close();
    },
  );

  test(
    'duplicate uploads are prevented; stale reads cannot replace newer data',
    () async {
      final repository = LogoRepositoryFake()
        ..readGate = Completer<BrandingLogo?>();
      final cubit = BrandingLogoCubit(repository, LogoPickerFake());
      final stale = cubit.load();
      final gate = repository.readGate!;
      repository.readGate = null;
      repository.value = logo('latest');
      await cubit.load();
      gate.complete(logo('old'));
      await stale;
      expect(cubit.state.logo!.version, 'latest');
      repository.uploadGate = Completer<BrandingLogo>();
      final pending = cubit.choose(isCurrent: () => true);
      expect(await cubit.choose(isCurrent: () => true), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(repository.uploads, 1);
      repository.uploadGate!.complete(logo('uploaded'));
      expect(await pending, isTrue);
      expect(cubit.state.logo!.version, 'uploaded');
      await cubit.close();
    },
  );

  group('branded logo editor', () {
    late LogoRepositoryFake repository;
    late LogoPickerFake picker;
    setUp(() async {
      await getIt.reset();
      repository = LogoRepositoryFake();
      picker = LogoPickerFake();
      getIt.registerFactory(() => BrandingLogoCubit(repository, picker));
    });
    tearDown(() => getIt.reset());
    Future<void> render(
      WidgetTester tester, {
      double width = 390,
      double scale = 1,
      bool knownLogo = false,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: BrandingLogoCard(hasStoredLogo: knownLogo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'saved logo previews in theme and picker cancellation keeps it unchanged',
      (tester) async {
        await render(tester);
        expect(find.byKey(const ValueKey('branding-logo-v1')), findsOneWidget);
        picker.value = null;
        await tester.tap(find.byKey(const ValueKey('branding-logo-upload')));
        await tester.pumpAndSettle();
        expect(repository.uploads, 0);
        expect(find.byKey(const ValueKey('branding-logo-v1')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'deleting a logo requires themed confirmation and cancel is non-mutating',
      (tester) async {
        await render(tester);
        await tester.tap(find.byKey(const ValueKey('branding-logo-remove')));
        await tester.pumpAndSettle();
        expect(find.byType(NalaraDialog), findsOneWidget);
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(repository.removals, 0);
        await tester.tap(find.byKey(const ValueKey('branding-logo-remove')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();
        expect(repository.removals, 1);
        expect(find.text('Belum ada logo'), findsOneWidget);
      },
    );
    testWidgets(
      'read failure keeps recovery actions without claiming no saved logo',
      (tester) async {
        repository.readError = const AppFailure(
          'Logo tersimpan belum dapat dibaca.',
        );
        await render(tester, knownLogo: true);
        expect(find.text('Belum ada logo'), findsNothing);
        expect(find.text('Logo tersimpan belum dapat dibaca.'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('branding-logo-remove')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.byKey(const ValueKey('branding-logo-upload')),
              )
              .onPressed,
          isNotNull,
        );
      },
    );
    testWidgets('320px and large text keep logo and actions scrollable', (
      tester,
    ) async {
      await render(tester, width: 320, scale: 2);
      await tester.ensureVisible(
        find.byKey(const ValueKey('branding-logo-upload')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
