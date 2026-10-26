import '../domain/avatar.dart';
import 'avatars_remote_source.dart';

class AvatarsRepositoryImpl implements AvatarsRepository {
  final AvatarsRemoteSource remote;
  AvatarsRepositoryImpl(this.remote);

  @override
  Future<List<ProfileAvatar>> options() async {
    final data = await remote.options();
    return List.unmodifiable(
      (data['items'] as List).map(
        (entry) => ProfileAvatar(
          id: entry['avatarId'] as String,
          label: entry['label'] as String,
          category: entry['category'] as String,
        ),
      ),
    );
  }

  @override
  Future<AvatarSelection> save(String? avatarId) async =>
      AvatarSelection((await remote.save(avatarId))['avatarId'] as String?);
}
