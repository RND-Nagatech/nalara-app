import 'app_role.dart';

class ReferralInvitation {
  final String id;
  final String? token;
  final AppRole audience;
  final DateTime expiresAt;
  final DateTime? revokedAt, redeemedAt;
  const ReferralInvitation({
    required this.id,
    this.token,
    this.audience = AppRole.student,
    required this.expiresAt,
    this.revokedAt,
    this.redeemedAt,
  });
}
