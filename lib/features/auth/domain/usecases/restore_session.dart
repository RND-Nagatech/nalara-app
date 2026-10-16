import '../../../access/domain/entities/app_role.dart';
import '../../../access/domain/entities/access_profile.dart';
import '../../../access/domain/repositories/access_repository.dart';
import '../entities/teacher.dart';
import '../repositories/auth_repository.dart';

class RestoredSession {
  final Teacher? teacher;
  final AccessProfile? profile;
  final bool onboardingSeen;
  final AppRole? role;
  const RestoredSession({
    this.teacher,
    this.profile,
    required this.onboardingSeen,
    this.role,
  });
}

class SessionRestoreFailure implements Exception {
  final Object cause;
  final bool onboardingSeen;
  final AppRole? role;
  const SessionRestoreFailure(
    this.cause, {
    required this.onboardingSeen,
    this.role,
  });
  @override
  String toString() => cause.toString();
}

/// A saved role is an entry preference used to choose between independently
/// persisted teacher and portal sessions. The server-authenticated session
/// still determines the actual role returned to the app.
class RestoreSession {
  final AuthRepository auth;
  final AccessRepository? access;
  RestoreSession(this.auth, this.access);
  Future<RestoredSession> call({
    bool previouslySeen = false,
    AppRole? previousRole,
  }) async {
    var seen = previouslySeen;
    AppRole? role = previousRole;
    try {
      await access?.initialize();
      seen = await auth.onboardingSeen();
      if (access != null) {
        role = await access!.savedRole() ?? previousRole;
      }

      Teacher? teacher;
      AccessProfile? profile;
      final portalPreferred = role == AppRole.student || role == AppRole.parent;
      if (portalPreferred) {
        profile = await access?.restore();
        teacher = profile == null ? await auth.restore() : null;
      } else {
        teacher = await auth.restore();
        profile = teacher == null ? await access?.restore() : null;
      }
      if (teacher != null) role = AppRole.teacher;
      if (profile != null) role = profile.role;
      if (teacher != null || profile != null) {
        await access?.saveRole(role);
        await auth.completeOnboarding();
        seen = true;
      }
      return RestoredSession(
        teacher: teacher,
        profile: profile,
        onboardingSeen: seen,
        role: role,
      );
    } catch (error) {
      throw SessionRestoreFailure(error, onboardingSeen: seen, role: role);
    }
  }
}
