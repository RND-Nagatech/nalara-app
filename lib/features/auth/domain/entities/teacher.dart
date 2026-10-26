class Teacher {
  final String id, name, email, workspaceId, timezone;
  final String? phone, avatarId;
  const Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.workspaceId,
    required this.timezone,
    this.phone,
    this.avatarId,
  });

  bool get missingPhone => phone?.trim().isNotEmpty != true;
  bool get missingAvatar => avatarId?.trim().isNotEmpty != true;
  int get incompleteProfileCount =>
      (missingPhone ? 1 : 0) + (missingAvatar ? 1 : 0);

  Teacher withTimezone(String timezone) => Teacher(
    id: id,
    name: name,
    email: email,
    workspaceId: workspaceId,
    timezone: timezone,
    phone: phone,
    avatarId: avatarId,
  );

  Teacher withPhone(String phone) => Teacher(
    id: id,
    name: name,
    email: email,
    workspaceId: workspaceId,
    timezone: timezone,
    phone: phone,
    avatarId: avatarId,
  );

  Teacher withAvatar(String? id) => Teacher(
    id: this.id,
    name: name,
    email: email,
    workspaceId: workspaceId,
    timezone: timezone,
    phone: phone,
    avatarId: id,
  );
}
