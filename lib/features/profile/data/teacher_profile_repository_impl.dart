import '../../../shared/errors/app_failure.dart';
import '../../../shared/domain/app_timezones.dart';
import '../../auth/domain/value_objects/phone_number.dart';
import '../domain/teacher_profile_repository.dart';
import 'teacher_profile_remote_source.dart';

class TeacherProfileRepositoryImpl implements TeacherProfileRepository {
  final TeacherProfileRemoteSource remote;
  TeacherProfileRepositoryImpl(this.remote);
  @override
  Future<String> updateTimezone(String timezone) async {
    if (!AppTimezones.supports(timezone)) {
      throw const AppFailure('Pilih zona waktu WIB, WITA, atau WIT.');
    }
    final data = await remote.updateTimezone(timezone);
    if (data['timezone'] != timezone) {
      throw const AppFailure(
        'Zona waktu belum dapat dikonfirmasi. Silakan coba lagi.',
        code: 'INVALID_RESPONSE',
      );
    }
    return timezone;
  }

  @override
  Future<String> updatePhone(String phone) async {
    final normalized = PhoneNumber.normalize(phone);
    if (normalized == null) {
      throw const AppFailure('Nomor HP Indonesia tidak valid');
    }
    final data = await remote.updatePhone(normalized);
    if (data['phone'] != normalized) {
      throw const AppFailure(
        'Nomor HP belum dapat dikonfirmasi. Silakan buka kembali profil Anda.',
        code: 'INVALID_RESPONSE',
      );
    }
    return normalized;
  }
}
