import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/auth/presentation/pages/auth_form_page.dart';
import 'package:nalara/features/auth/presentation/pages/legal_document_page.dart';
import 'package:nalara/features/auth/presentation/widgets/auth_palette.dart';
import 'package:nalara/features/auth/presentation/widgets/plain_text_action.dart';
import 'package:nalara/features/auth/presentation/widgets/terms_consent.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'package:nalara/shared/errors/app_failure.dart';

class FormAuth extends AuthRepository {
  int loginCalls = 0;
  int googleCalls = 0;
  int registerCalls = 0;
  String? identifier, registeredEmail, registeredPhone;
  bool? remembered;
  Completer<void>? gate;
  bool fail = false;
  String? backendError;
  String? registeredConfirmation;
  LoginMethod? method;
  static const teacher = Teacher(
    id: 't',
    name: 'Guru',
    email: 'guru@example.test',
    phone: '+6281234567890',
    workspaceId: 'w',
    timezone: 'Asia/Jakarta',
  );

  @override
  Future<Teacher> login(
    String identifier,
    String password, {
    bool rememberMe = true,
    LoginMethod method = LoginMethod.email,
  }) async {
    loginCalls++;
    this.identifier = identifier;
    remembered = rememberMe;
    this.method = method;
    await gate?.future;
    if (fail) throw Exception('Email/nomor HP atau kata sandi salah');
    if (backendError != null) throw AppFailure(backendError!);
    return teacher;
  }

  @override
  Future<Teacher> loginWithGoogle({bool rememberMe = true}) async {
    googleCalls++;
    return teacher;
  }

  @override
  Future<Teacher> register(
    String name,
    String email,
    String password, {
    required String phone,
    required String passwordConfirmation,
  }) async {
    registerCalls++;
    registeredEmail = email;
    registeredPhone = phone;
    registeredConfirmation = passwordConfirmation;
    if (backendError != null) throw AppFailure(backendError!);
    return teacher;
  }

  @override
  Future<void> completeOnboarding() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<({FormAuth repository, GoRouter router})> mountForm(
  WidgetTester tester, {
  bool register = false,
  Size size = const Size(390, 844),
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = FormAuth();
  final auth = AuthCubit(repository);
  getIt.registerSingleton(auth);
  final router = GoRouter(
    initialLocation: register ? '/register' : '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const AuthFormPage()),
      GoRoute(
        path: '/register',
        builder: (_, _) => const AuthFormPage(register: true),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const Scaffold(body: Text('Pulihkan akun')),
      ),
      GoRoute(
        path: '/legal/syarat-dan-ketentuan',
        builder: (_, _) =>
            const LegalDocumentPage(kind: LegalDocumentKind.terms),
      ),
      GoRoute(
        path: '/legal/kebijakan-privasi',
        builder: (_, _) =>
            const LegalDocumentPage(kind: LegalDocumentKind.privacy),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: buildAppTheme(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 44, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 44, bottom: 24),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await auth.close();
    await getIt.reset();
  });
  return (repository: repository, router: router);
}

Finder authField(String name) => find.byKey(ValueKey('auth-$name'));
TextField authInput(WidgetTester tester, String name) =>
    tester.widget<TextField>(
      find.descendant(of: authField(name), matching: find.byType(TextField)),
    );
Future<void> submitForm(WidgetTester tester) async {
  await tester.ensureVisible(authField('submit'));
  await tester.pumpAndSettle();
  await tester.tap(authField('submit'));
}

Future<void> acceptTerms(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('auth-terms')));
  await tester.tap(find.byKey(const ValueKey('auth-terms')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'asset is confined to header; lower form and safe bottom match onboarding',
    (tester) async {
      await mountForm(tester);
      final image = tester.widget<Image>(
        find.byKey(const ValueKey('auth-login-header-art')),
      );
      expect((image.image as AssetImage).assetName, 'assets/Login/Login.png');
      expect(find.byType(Image), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('auth-login-header'))).height,
        lessThan(450),
      );
      expect(
        tester
            .widget<ColoredBox>(
              find.byKey(const ValueKey('auth-form-background')),
            )
            .color,
        AuthPalette.cream,
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AuthPalette.cream,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SafeArea && !widget.top && widget.bottom,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SafeArea && widget.top && !widget.bottom,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'only green Daftar Guru link navigates; account prompt stays black/plain',
    (tester) async {
      final harness = await mountForm(tester);
      final prompt = find.byKey(const ValueKey('auth-account-prompt'));
      await tester.ensureVisible(prompt);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(prompt).style!.color, Colors.black87);
      expect(
        find.ancestor(of: prompt, matching: find.byType(TextButton)),
        findsNothing,
      );
      await tester.tap(prompt);
      await tester.pumpAndSettle();
      expect(harness.router.routeInformationProvider.value.uri.path, '/login');
      final link = tester.widget<PlainTextAction>(
        find.byKey(const ValueKey('auth-account-link')),
      );
      expect(link.color, AuthPalette.green);
      final linkButton = tester.widget<TextButton>(
        find.descendant(
          of: find.byKey(const ValueKey('auth-account-link')),
          matching: find.byType(TextButton),
        ),
      );
      expect(
        linkButton.style!.overlayColor!.resolve({WidgetState.pressed}),
        Colors.transparent,
      );
      expect(linkButton.style!.splashFactory, NoSplash.splashFactory);
      await tester.tap(find.text('Daftar Guru'));
      await tester.pumpAndSettle();
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/register',
      );
      expect(authField('email'), findsOneWidget);
      expect(authField('phone'), findsOneWidget);
    },
  );
  testWidgets('email and phone tabs retain independent values and password', (
    tester,
  ) async {
    await mountForm(tester);
    await tester.enterText(authField('email'), 'guru@example.test');
    await tester.enterText(authField('password'), 'StrongPassword123!');
    await tester.tap(find.text('Nomor HP'));
    await tester.pumpAndSettle();
    expect(authField('email'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: authField('phone'),
              matching: find.byType(TextField),
            ),
          )
          .keyboardType,
      TextInputType.phone,
    );
    await tester.enterText(authField('phone'), '081234567890');
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(authField('email')).controller!.text,
      'guru@example.test',
    );
    expect(
      tester.widget<TextFormField>(authField('password')).controller!.text,
      'StrongPassword123!',
    );
    await tester.tap(find.text('Nomor HP'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(authField('phone')).controller!.text,
      '081234567890',
    );
  });
  testWidgets(
    'phone login passes remember choice and renders authoritative backend errors',
    (tester) async {
      final harness = await mountForm(tester);
      harness.repository.backendError = 'Nomor HP Indonesia tidak valid';
      await tester.tap(find.text('Nomor HP'));
      await tester.pumpAndSettle();
      await tester.enterText(authField('phone'), 'bad-phone');
      await tester.enterText(authField('password'), 'StrongPassword123!');
      await submitForm(tester);
      await tester.pumpAndSettle();
      expect(harness.repository.loginCalls, 1);
      expect(find.text('Nomor HP Indonesia tidak valid'), findsOneWidget);
      harness.repository.backendError = null;
      await tester.enterText(authField('phone'), '0812-3456-7890');
      await tester.tap(find.byKey(const ValueKey('auth-remember-me')));
      await submitForm(tester);
      await tester.pumpAndSettle();
      expect(harness.repository.identifier, '0812-3456-7890');
      expect(harness.repository.remembered, isFalse);
      expect(harness.repository.loginCalls, 2);
      expect(harness.repository.method, LoginMethod.phone);
    },
  );
  testWidgets(
    'registration sends all five fields and shows backend validation unchanged',
    (tester) async {
      final harness = await mountForm(tester, register: true);
      harness.repository.backendError = 'Nomor HP wajib diisi';
      await tester.enterText(authField('name'), 'Guru Baru');
      await tester.enterText(authField('email'), 'guru@example.test');
      await tester.enterText(authField('password'), 'StrongPassword123!');
      await acceptTerms(tester);
      await submitForm(tester);
      await tester.pumpAndSettle();
      expect(harness.repository.registerCalls, 1);
      expect(find.text('Nomor HP wajib diisi'), findsOneWidget);
      harness.repository.backendError = null;
      await tester.enterText(authField('phone'), '081234567890');
      await tester.enterText(
        authField('password-confirmation'),
        'StrongPassword123!',
      );
      await submitForm(tester);
      await tester.pumpAndSettle();
      expect(harness.repository.registeredEmail, 'guru@example.test');
      expect(harness.repository.registeredPhone, '081234567890');
      expect(harness.repository.registeredConfirmation, 'StrongPassword123!');
      expect(harness.repository.registerCalls, 2);
    },
  );
  testWidgets(
    'pending login prevents double submit and error stays retryable',
    (tester) async {
      final harness = await mountForm(tester);
      harness.repository.gate = Completer<void>();
      harness.repository.fail = true;
      await tester.enterText(authField('email'), 'guru@example.test');
      await tester.enterText(authField('password'), 'StrongPassword123!');
      await submitForm(tester);
      await tester.pump();
      expect(
        tester.widget<FilledButton>(authField('submit')).onPressed,
        isNull,
      );
      expect(harness.repository.loginCalls, 1);
      harness.repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Email/nomor HP atau kata sandi salah'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(authField('submit')).onPressed,
        isNotNull,
      );
    },
  );
  testWidgets(
    'register uses logo asset, plain phone field and independent password toggles',
    (tester) async {
      await mountForm(tester, register: true);
      final logo = tester.widget<Image>(
        find.byKey(const ValueKey('register-logo')),
      );
      expect((logo.image as AssetImage).assetName, 'assets/Logo/LOGO.png');
      final phone = authInput(tester, 'phone');
      expect(phone.decoration!.prefixText, isNull);
      expect(find.text('+62'), findsNothing);
      expect(authField('password-confirmation'), findsOneWidget);
      expect(authInput(tester, 'password').obscureText, isTrue);
      await tester.ensureVisible(authField('password-confirmation'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tampilkan ulangi kata sandi'));
      await tester.pumpAndSettle();
      expect(authInput(tester, 'password-confirmation').obscureText, isFalse);
      expect(authInput(tester, 'password').obscureText, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'register requires legal consent and opens both legal documents',
    (tester) async {
      final harness = await mountForm(tester, register: true);
      expect(
        tester.widget<FilledButton>(authField('submit')).onPressed,
        isNotNull,
      );
      await submitForm(tester);
      await tester.pumpAndSettle();
      expect(harness.repository.registerCalls, 0);
      expect(
        tester.widget<TermsConsent>(find.byType(TermsConsent)).hasError,
        isTrue,
      );
      expect(
        find.text(
          'Setujui syarat dan kebijakan terlebih dahulu.',
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      harness.router.go('/legal/syarat-dan-ketentuan');
      await tester.pumpAndSettle();
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/legal/syarat-dan-ketentuan',
      );
      expect(find.byType(LegalDocumentPage), findsOneWidget);
      harness.router.go('/legal/kebijakan-privasi');
      await tester.pumpAndSettle();
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/legal/kebijakan-privasi',
      );
      expect(find.byType(LegalDocumentPage), findsOneWidget);
    },
  );
  testWidgets(
    'Flutter forwards an eight-character password and backend guard messages unchanged',
    (tester) async {
      final harness = await mountForm(tester, register: true);
      harness.repository.backendError =
          'Email tersebut sudah terdaftar. Silakan login atau ganti kata sandi.';
      await tester.enterText(authField('name'), 'Guru');
      await tester.enterText(authField('email'), 'existing@example.test');
      await tester.enterText(authField('phone'), '081234567890');
      await tester.enterText(authField('password'), 'Aa1!abcd');
      await tester.enterText(authField('password-confirmation'), 'different');
      await acceptTerms(tester);
      await submitForm(tester);
      await tester.pumpAndSettle();
      expect(harness.repository.registerCalls, 1);
      expect(harness.repository.registeredConfirmation, 'different');
      expect(find.text(harness.repository.backendError!), findsOneWidget);
    },
  );
  testWidgets('Google login is available while Apple stays hidden', (
    tester,
  ) async {
    final harness = await mountForm(tester);
    expect(find.byKey(const ValueKey('auth-social-apple')), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('auth-social-google')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('auth-social-google')));
    await tester.pumpAndSettle();
    expect(harness.repository.googleCalls, 1);
  });
  testWidgets(
    'small screen and visible keyboard scroll without layout overflow',
    (tester) async {
      await mountForm(tester, size: const Size(320, 568), keyboard: 250);
      await tester.ensureVisible(authField('password'));
      await tester.pumpAndSettle();
      await tester.enterText(authField('password'), 'StrongPassword123!');
      expect(tester.takeException(), isNull);
    },
  );
}
