class ProfileAvatar {
  final String id, label, category;
  const ProfileAvatar({
    required this.id,
    required this.label,
    required this.category,
  });
}

class AvatarSelection {
  final String? avatarId;
  const AvatarSelection(this.avatarId);
}

abstract class AvatarsRepository {
  Future<List<ProfileAvatar>> options();
  Future<AvatarSelection> save(String? avatarId);
}
