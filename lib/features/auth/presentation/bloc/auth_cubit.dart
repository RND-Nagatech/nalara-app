import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/restore_session.dart';
import '../../../access/domain/entities/app_role.dart';
import '../../../access/domain/entities/access_profile.dart';
import '../../../access/domain/repositories/access_repository.dart';
import '../../../../shared/notifications/push_notification_service.dart';

enum AuthStatus {
  initial,
  restoring,
  authenticated,
  portalAuthenticated,
  unauthenticated,
  failure,
}

class AuthState {
  final AuthStatus status;
  final Teacher? teacher;
  final String? error;
  final bool onboardingSeen;
  final AppRole? selectedRole;
  final AccessProfile? accessProfile;
  const AuthState(
    this.status, {
    this.teacher,
    this.error,
    this.onboardingSeen = false,
    this.selectedRole,
    this.accessProfile,
  });
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  final AccessRepository? access;
  final PushNotificationService? push;
  final RestoreSession restoreSession;
  AuthCubit(
    this.repository, {
    this.access,
    this.push,
    RestoreSession? restoreSession,
  }) : restoreSession = restoreSession ?? RestoreSession(repository, access),
       super(const AuthState(AuthStatus.initial));
  Future<void> restore() async {
    if (isClosed) return;
    emit(
      AuthState(
        AuthStatus.restoring,
        onboardingSeen: state.onboardingSeen,
        selectedRole: state.selectedRole,
      ),
    );
    try {
      final session = await restoreSession(
        previouslySeen: state.onboardingSeen,
        previousRole: state.selectedRole,
      );
      if (isClosed) return;
      emit(
        AuthState(
          session.teacher != null
              ? AuthStatus.authenticated
              : session.profile != null
              ? AuthStatus.portalAuthenticated
              : AuthStatus.unauthenticated,
          teacher: session.teacher,
          onboardingSeen: session.onboardingSeen,
          selectedRole: session.role,
          accessProfile: session.profile,
        ),
      );
    } on SessionRestoreFailure catch (error) {
      if (!isClosed) {
        emit(
          AuthState(
            AuthStatus.failure,
            error: error.toString(),
            onboardingSeen: error.onboardingSeen,
            selectedRole: error.role,
          ),
        );
      }
    }
  }

  Future<void> login(
    String identifier,
    String password, {
    bool rememberMe = true,
    LoginMethod method = LoginMethod.email,
  }) async {
    final teacher = await repository.login(
      identifier,
      password,
      rememberMe: rememberMe,
      method: method,
    );
    await access?.saveRole(AppRole.teacher);
    await repository.completeOnboarding();
    if (isClosed) return;
    emit(
      AuthState(
        AuthStatus.authenticated,
        teacher: teacher,
        onboardingSeen: true,
        selectedRole: AppRole.teacher,
      ),
    );
  }

  Future<void> loginWithGoogle({bool rememberMe = true}) async {
    final teacher = await repository.loginWithGoogle(rememberMe: rememberMe);
    await access?.saveRole(AppRole.teacher);
    await repository.completeOnboarding();
    if (isClosed) return;
    emit(
      AuthState(
        AuthStatus.authenticated,
        teacher: teacher,
        onboardingSeen: true,
        selectedRole: AppRole.teacher,
      ),
    );
  }

  Future<void> register(
    String name,
    String email,
    String password, {
    required String phone,
    required String passwordConfirmation,
  }) async {
    await repository.register(
      name,
      email,
      password,
      phone: phone,
      passwordConfirmation: passwordConfirmation,
    );
    if (isClosed) return;
    // Creating an account must not sign the user in automatically. The form
    // shows a success notice and sends the user to the login page instead.
    emit(
      AuthState(
        AuthStatus.unauthenticated,
        onboardingSeen: state.onboardingSeen,
        selectedRole: AppRole.teacher,
      ),
    );
  }

  Future<void> completeOnboarding() async {
    await repository.completeOnboarding();
    if (isClosed) return;
    emit(
      AuthState(
        AuthStatus.unauthenticated,
        onboardingSeen: true,
        selectedRole: state.selectedRole,
      ),
    );
  }

  Future<void> chooseRole(AppRole role) async {
    await access?.saveRole(role);
    await repository.completeOnboarding();

    // Teacher and portal sessions are kept in separate secure-storage
    // namespaces. Resume the selected role when it already has a valid
    // server session instead of forcing the user to log in or redeem a code
    // again after switching roles.
    final teacher = role == AppRole.teacher ? await repository.restore() : null;
    final profile = role == AppRole.teacher ? null : await access?.restore();
    if (!isClosed && (teacher != null || profile != null)) {
      emit(
        AuthState(
          teacher != null
              ? AuthStatus.authenticated
              : AuthStatus.portalAuthenticated,
          teacher: teacher,
          onboardingSeen: true,
          selectedRole: profile?.role ?? AppRole.teacher,
          accessProfile: profile,
        ),
      );
      return;
    }

    if (!isClosed) {
      emit(
        AuthState(
          AuthStatus.unauthenticated,
          onboardingSeen: true,
          selectedRole: role,
        ),
      );
    }
  }

  Future<void> redeemReferral(String code, AppRole role) async {
    final service = access;
    if (service == null) {
      throw StateError('Layanan referral belum dikonfigurasi');
    }
    final profile = await service.redeem(code, role);
    if (!isClosed) {
      emit(
        AuthState(
          AuthStatus.portalAuthenticated,
          onboardingSeen: true,
          selectedRole: profile.role,
          accessProfile: profile,
        ),
      );
    }
  }

  Future<void> changeUser() async {
    await push?.deactivate();

    // Switching users/roles is not a logout. Keep the independently stored
    // sessions so the last selected role can be restored on the next launch
    // and a redeemed referral code is never requested a second time.
    if (!isClosed) {
      emit(const AuthState(AuthStatus.unauthenticated, onboardingSeen: true));
    }
  }

  Future<void> logout() async {
    await push?.deactivate();
    await repository.logout();
    expire();
  }

  void expire() {
    if (!isClosed && state.status == AuthStatus.authenticated) {
      emit(
        const AuthState(
          AuthStatus.unauthenticated,
          onboardingSeen: true,
          selectedRole: AppRole.teacher,
        ),
      );
    }
  }

  void expirePortal() {
    if (!isClosed && state.status == AuthStatus.portalAuthenticated) {
      emit(
        AuthState(
          AuthStatus.unauthenticated,
          onboardingSeen: true,
          selectedRole: state.selectedRole,
        ),
      );
    }
  }
}
