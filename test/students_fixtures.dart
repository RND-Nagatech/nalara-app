import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/domain/repositories/students_repository.dart';
import 'package:nalara/shared/domain/page.dart';

typedef StudentsRequest = ({int page, String search, String? status});
Student studentFixture(String id, String name, {String status = 'active'}) =>
    Student(id: id, name: name, grade: 'Kelas 5', notes: '', status: status);

class StudentsRepositoryFake implements StudentsRepository {
  final calls = <StudentsRequest>[];
  List<Student> records = [];
  int limit = 30;
  Object? error;
  Future<PageResult<Student>> Function(StudentsRequest request)? respond;
  @override
  Future<PageResult<Student>> list({
    int page = 1,
    String search = '',
    String? status,
  }) async {
    final request = (page: page, search: search, status: status);
    calls.add(request);
    if (respond != null) return await respond!(request);
    if (error != null) throw error!;
    final matches = records
        .where(
          (student) =>
              (status == null || student.status == status) &&
              student.name.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    return PageResult(
      items: matches.skip((page - 1) * limit).take(limit).toList(),
      total: matches.length,
      page: page,
      limit: limit,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
