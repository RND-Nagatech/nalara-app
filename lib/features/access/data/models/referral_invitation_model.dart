import '../../domain/entities/app_role.dart';
import '../../domain/entities/referral_invitation.dart';

class ReferralInvitationModel {
  final Map<String, dynamic> json;
  ReferralInvitationModel(this.json);
  ReferralInvitation toEntity() => ReferralInvitation(
    id: json['_id'] as String,
    token: json['token'] as String?,
    audience: json['audience'] == 'parent' ? AppRole.parent : AppRole.student,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    revokedAt: json['revokedAt'] == null
        ? null
        : DateTime.parse(json['revokedAt'] as String),
    redeemedAt: json['redeemedAt'] == null
        ? null
        : DateTime.parse(json['redeemedAt'] as String),
  );
}
