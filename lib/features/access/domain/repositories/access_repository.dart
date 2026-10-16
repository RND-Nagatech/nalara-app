import '../entities/app_role.dart';
import '../entities/access_profile.dart';

abstract class AccessRepository {
  Future<void> initialize();
  Future<AppRole?> savedRole();
  Future<void> saveRole(AppRole? role);
  Future<AccessProfile?> restore();
  Future<AccessProfile> redeem(String code, AppRole role);
  Future<void> logout();
}
