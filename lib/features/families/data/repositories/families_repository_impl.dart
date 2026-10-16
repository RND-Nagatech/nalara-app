import '../../../../shared/domain/page.dart';
import '../../../../shared/errors/app_failure.dart';
import '../../../access/data/models/referral_invitation_model.dart';
import '../../../access/domain/entities/referral_invitation.dart';
import '../../../auth/domain/value_objects/phone_number.dart';
import '../../domain/entities/family.dart';
import '../../domain/repositories/families_repository.dart';
import '../datasources/families_remote_source.dart';
import '../models/family_model.dart';

class FamiliesRepositoryImpl implements FamiliesRepository {
  final FamiliesRemoteSource remote;
  FamiliesRepositoryImpl(this.remote);
  Map<String, dynamic> _fields(FamilyDraft draft) => {
    'parentName': draft.parentName.trim(),
    'parentPhone':
        PhoneNumber.normalize(draft.parentPhone) ?? draft.parentPhone.trim(),
    'studentIds': draft.studentIds,
    if (draft.version != null) 'version': draft.version,
  };
  @override
  Future<PageResult<Family>> list({int page = 1, String search = ''}) async {
    final data = await remote.list(page, search);
    return PageResult(
      items: (data['items'] as List)
          .map((row) => FamilyModel(Map<String, dynamic>.from(row)).toEntity())
          .toList(),
      total: data['total'],
      page: data['page'],
      limit: data['limit'],
    );
  }

  @override
  Future<Family> get(String id) async =>
      FamilyModel(await remote.get(id)).toEntity();
  @override
  Future<Family> create(FamilyDraft draft) async =>
      FamilyModel(await remote.create(_fields(draft))).toEntity();
  @override
  Future<Family> update(String id, FamilyDraft draft) async {
    if (draft.version == null) {
      throw const AppFailure('Muat ulang data keluarga sebelum menyimpan.');
    }
    return FamilyModel(await remote.update(id, _fields(draft))).toEntity();
  }

  @override
  Future<ReferralInvitation> createCode(String id) async =>
      ReferralInvitationModel(await remote.createCode(id)).toEntity();
  @override
  Future<List<ReferralInvitation>> invitations(String id) async =>
      ((await remote.invitations(id))['items'] as List)
          .map(
            (row) => ReferralInvitationModel(
              Map<String, dynamic>.from(row),
            ).toEntity(),
          )
          .toList();
  @override
  Future<void> revokeCode(String id, String invitationId) =>
      remote.revokeCode(id, invitationId);
  @override
  Future<void> revokeAccess(String id) => remote.revokeAccess(id);
}
