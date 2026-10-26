import '../../../shared/domain/page.dart';
import 'student_group.dart';

abstract class StudentGroupsRepository {
  Future<PageResult<StudentGroup>> list({
    int page = 1,
    int limit = 5,
    String search = '',
  });
  Future<StudentGroup> get(String id);
  Future<void> save({
    String? id,
    int? version,
    required String name,
    required List<String> studentIds,
  });
  Future<void> remove(String id, int version);
}
