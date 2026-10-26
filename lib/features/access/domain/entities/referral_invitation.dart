import 'app_role.dart';

class ReferralInvitation {
  final String id;
  final String? token;
  final AppRole audience;
  final DateTime? expiresAt;
  final DateTime? revokedAt, redeemedAt, lastUsedAt;
  const ReferralInvitation({
    required this.id,
    this.token,
    this.audience = AppRole.student,
    this.expiresAt,
    this.revokedAt,
    this.redeemedAt,
    this.lastUsedAt,
  });
}
