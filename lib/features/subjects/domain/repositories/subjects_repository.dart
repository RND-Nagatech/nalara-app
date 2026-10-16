import '../../../../shared/domain/page.dart';
import '../entities/subject.dart';

abstract class SubjectsRepository {
  Future<PageResult<Subject>> list({int page = 1});
  Future<Subject> create(String name);
  Future<Subject> get(String id);
  Future<Subject> update(String id, String name);
}
