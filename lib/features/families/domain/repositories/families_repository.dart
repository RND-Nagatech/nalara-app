import '../../../../shared/domain/page.dart';
import '../../../access/domain/entities/referral_invitation.dart';
import '../entities/family.dart';

abstract class FamiliesRepository {
  Future<PageResult<Family>> list({int page = 1, String search = ''});
  Future<Family> get(String id);
  Future<Family> create(FamilyDraft draft);
  Future<Family> update(String id, FamilyDraft draft);
  Future<ReferralInvitation> createCode(String id);
  Future<List<ReferralInvitation>> invitations(String id);
  Future<void> revokeCode(String id, String invitationId);
  Future<void> revokeAccess(String id);
}
