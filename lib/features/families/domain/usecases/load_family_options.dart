import '../../../students/domain/entities/student.dart';
import '../../../students/domain/repositories/students_repository.dart';
import '../entities/family.dart';
import '../repositories/families_repository.dart';

/// Loads every page so children/families beyond the first page stay selectable.
class LoadFamilyStudents {
  final StudentsRepository students;
  LoadFamilyStudents(this.students);
  Future<List<Student>> call() async {
    final result = <Student>[];
    for (var page = 1; ; page++) {
      final batch = await students.list(page: page);
      result.addAll(batch.items);
      if (batch.items.isEmpty || batch.page * batch.limit >= batch.total) break;
    }
    return List.unmodifiable(result);
  }
}

class LoadFamilies {
  final FamiliesRepository families;
  LoadFamilies(this.families);
  Future<List<Family>> call() async {
    final result = <Family>[];
    for (var page = 1; ; page++) {
      final batch = await families.list(page: page);
      result.addAll(batch.items);
      if (batch.items.isEmpty || batch.page * batch.limit >= batch.total) break;
    }
    return List.unmodifiable(result);
  }
}
