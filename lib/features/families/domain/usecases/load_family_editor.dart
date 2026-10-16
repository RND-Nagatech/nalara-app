import '../../../access/domain/entities/referral_invitation.dart';
import '../../../students/domain/entities/student.dart';
import '../entities/family.dart';
import '../repositories/families_repository.dart';
import 'load_family_options.dart';

typedef FamilyEditorOptions = ({Family? family, List<Student> students});
typedef FamilyOverview = ({
  Family family,
  List<ReferralInvitation> invitations,
});

class LoadFamilyEditor {
  final FamiliesRepository families;
  final LoadFamilyStudents children;
  LoadFamilyEditor(this.families, this.children);
  Future<FamilyEditorOptions> call(String? id) async {
    final family = id == null ? null : await families.get(id);
    return (family: family, students: await children());
  }
}

class LoadFamilyOverview {
  final FamiliesRepository families;
  LoadFamilyOverview(this.families);
  Future<FamilyOverview> call(String id) async => (
    family: await families.get(id),
    invitations: await families.invitations(id),
  );
}
