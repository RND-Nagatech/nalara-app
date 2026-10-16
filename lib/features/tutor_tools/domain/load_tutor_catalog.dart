import '../../students/domain/entities/student.dart';
import '../../students/domain/repositories/students_repository.dart';
import '../../subjects/domain/entities/subject.dart';
import '../../subjects/domain/repositories/subjects_repository.dart';

typedef TutorCatalog = ({List<Student> students, List<Subject> subjects});

class LoadTutorCatalog {
  final StudentsRepository students;
  final SubjectsRepository subjects;
  LoadTutorCatalog(this.students, this.subjects);
  Future<TutorCatalog> call() async {
    final studentRows = <Student>[], subjectRows = <Subject>[];
    for (var page = 1; ; page++) {
      final result = await students.list(page: page, status: 'active');
      studentRows.addAll(result.items);
      if (!result.hasNext) break;
    }
    for (var page = 1; ; page++) {
      final result = await subjects.list(page: page);
      subjectRows.addAll(result.items);
      if (!result.hasNext) break;
    }
    return (
      students: List<Student>.unmodifiable(studentRows),
      subjects: List<Subject>.unmodifiable(subjectRows),
    );
  }
}
