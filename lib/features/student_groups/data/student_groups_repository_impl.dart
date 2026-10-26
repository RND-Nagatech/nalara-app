import '../../../shared/domain/page.dart';
import '../domain/student_group.dart';
import '../domain/student_groups_repository.dart';
import 'student_group_model.dart';
import 'student_groups_remote_source.dart';

class StudentGroupsRepositoryImpl implements StudentGroupsRepository {
  final StudentGroupsRemoteSource remote;
  StudentGroupsRepositoryImpl(this.remote);
  @override
  Future<PageResult<StudentGroup>> list({
    int page = 1,
    int limit = 5,
    String search = '',
  }) async {
    final data = await remote.list(page, limit, search);
    return PageResult(
      items: (data['items'] as List)
          .map(
            (row) =>
                StudentGroupModel(Map<String, dynamic>.from(row)).toEntity(),
          )
          .toList(),
      total: data['total'] as int,
      page: data['page'] as int,
      limit: data['limit'] as int,
    );
  }

  @override
  Future<StudentGroup> get(String id) async =>
      StudentGroupModel(await remote.get(id)).toEntity();
  @override
  Future<void> save({
    String? id,
    int? version,
    required String name,
    required List<String> studentIds,
  }) => remote.save(id, {
    'name': name.trim(),
    'studentIds': studentIds,
    if (id != null) 'version': version,
  });
  @override
  Future<void> remove(String id, int version) => remote.remove(id, version);
}
