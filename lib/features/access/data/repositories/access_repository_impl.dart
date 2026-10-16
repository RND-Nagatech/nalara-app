import '../../../../shared/errors/app_failure.dart';
import '../../../../shared/network/token_store.dart';
import '../../domain/entities/app_role.dart';
import '../../domain/entities/access_profile.dart';
import '../../domain/repositories/access_repository.dart';
import '../datasources/access_local_source.dart';
import '../datasources/access_remote_source.dart';
import '../models/access_profile_model.dart';

class AccessRepositoryImpl implements AccessRepository {
  final AccessRemoteSource remote;
  final AccessLocalSource local;
  final TokenStore tokens;
  AccessRepositoryImpl(this.remote, this.local, this.tokens);
  @override
  Future<void> initialize() => local.initialize();
  @override
  Future<AppRole?> savedRole() async => switch (await local.readRole()) {
    'teacher' => AppRole.teacher,
    'student' => AppRole.student,
    'parent' => AppRole.parent,
    _ => null,
  };
  @override
  Future<void> saveRole(AppRole? role) => local.writeRole(role?.name);
  @override
  Future<AccessProfile?> restore() async {
    await tokens.restore();
    if (tokens.refreshToken == null) return null;
    try {
      return AccessProfileModel(await remote.me()).toEntity();
    } on AppFailure catch (error) {
      if (error.code != 'UNAUTHENTICATED') rethrow;
      await tokens.clear();
      return null;
    }
  }

  @override
  Future<AccessProfile> redeem(String code, AppRole role) async {
    final data = await remote.redeem(code, role.name);
    final profile = AccessProfileModel(
      Map<String, dynamic>.from(data['profile']),
    ).toEntity();
    await tokens.save(
      data['accessToken'] as String,
      data['refreshToken'] as String,
      persist: true,
    );
    await saveRole(profile.role);
    return profile;
  }

  @override
  Future<void> logout() async {
    if (tokens.refreshToken != null) {
      try {
        await remote.logout(tokens.refreshToken!);
      } on AppFailure catch (error) {
        if (error.code != 'UNAUTHENTICATED') rethrow;
      }
    }
    await tokens.clear();
  }
}
