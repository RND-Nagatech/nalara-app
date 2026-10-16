import '../../../../shared/errors/app_failure.dart';
import '../../domain/entities/app_role.dart';
import '../../domain/entities/access_profile.dart';

class AccessProfileModel {
  final Map<String, dynamic> json;
  AccessProfileModel(this.json);
  AccessProfile toEntity() {
    final role = switch (json['role']) {
      'student' => AppRole.student,
      'parent' => AppRole.parent,
      _ => throw const AppFailure(
        'Respons sesi referral tidak sesuai.',
        code: 'INVALID_RESPONSE',
      ),
    };
    return AccessProfile(
      role: role,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      familyName: json['familyName'] as String?,
      familyId: json['familyId'] as String?,
      children: List.unmodifiable(
        (json['students'] as List).map(
          (row) => LinkedChild(
            id: row['_id'] as String,
            name: row['name'] as String,
            grade: row['grade'] as String? ?? '',
          ),
        ),
      ),
    );
  }
}
