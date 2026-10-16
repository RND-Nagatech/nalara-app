import 'app_role.dart';

class LinkedChild {
  final String id, name, grade;
  const LinkedChild({
    required this.id,
    required this.name,
    required this.grade,
  });
}

class AccessProfile {
  final AppRole role;
  final String name;
  final String? phone, familyName;
  final String? familyId;
  final List<LinkedChild> children;
  const AccessProfile({
    required this.role,
    required this.name,
    this.phone,
    this.familyName,
    this.familyId,
    required this.children,
  });
}
