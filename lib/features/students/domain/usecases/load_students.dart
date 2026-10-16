import '../../../../shared/domain/page.dart';
import '../entities/student.dart';
import '../entities/student_filter.dart';
import '../repositories/students_repository.dart';

class LoadStudents {
  final Future<PageResult<Student>> Function({
    int page,
    String search,
    String? status,
  })
  _read;
  LoadStudents(StudentsRepository repository) : _read = repository.list;
  LoadStudents.fromReader(this._read);
  Future<PageResult<Student>> call({
    StudentFilter filter = StudentFilter.active,
    String search = '',
    int page = 1,
  }) async {
    final result = await _read(
      page: page,
      search: search.trim(),
      status: filter.status,
    );
    return PageResult(
      items: List.unmodifiable(result.items),
      total: result.total,
      page: result.page,
      limit: result.limit,
    );
  }
}
