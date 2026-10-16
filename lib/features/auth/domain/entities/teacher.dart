class Teacher {
  final String id, name, email, workspaceId, timezone;
  final String? phone;
  const Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.workspaceId,
    required this.timezone,
    this.phone,
  });
}
