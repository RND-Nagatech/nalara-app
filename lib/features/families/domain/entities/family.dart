class FamilyChild {
  final String id, name, grade, status;
  const FamilyChild({
    required this.id,
    required this.name,
    required this.grade,
    required this.status,
  });
}

class Family {
  final String id, parentName, parentPhone;
  final int version;
  final List<FamilyChild> children;
  const Family({
    required this.id,
    required this.parentName,
    required this.parentPhone,
    required this.version,
    required this.children,
  });
}

class FamilyDraft {
  final String parentName, parentPhone;
  final List<String> studentIds;
  final int? version;
  const FamilyDraft({
    required this.parentName,
    required this.parentPhone,
    required this.studentIds,
    this.version,
  });
}
