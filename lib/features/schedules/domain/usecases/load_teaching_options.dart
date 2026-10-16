import '../../../students/domain/entities/student.dart';
import '../../../students/domain/repositories/students_repository.dart';
import '../../../subjects/domain/entities/subject.dart';
import '../../../subjects/domain/repositories/subjects_repository.dart';

class TeachingOptions {
  final List<Student> students;
  final List<Subject> subjects;
  const TeachingOptions(this.students, this.subjects);
}

class LoadTeachingOptions {
  final StudentsRepository students;
  final SubjectsRepository subjects;
  LoadTeachingOptions(this.students, this.subjects);
  Future<TeachingOptions> call() async {
    final studentItems = <Student>[], subjectItems = <Subject>[];
    var page = 1;
    while (true) {
      final result = await students.list(page: page, status: 'active');
      studentItems.addAll(result.items);
      if (!result.hasNext) break;
      page++;
    }
    page = 1;
    while (true) {
      final result = await subjects.list(page: page);
      subjectItems.addAll(result.items);
      if (!result.hasNext) break;
      page++;
    }
    return TeachingOptions(studentItems, subjectItems);
  }
}
