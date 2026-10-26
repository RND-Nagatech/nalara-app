import '../../students/domain/entities/student.dart';
import '../../students/domain/repositories/students_repository.dart';
import 'student_group.dart';
import 'student_groups_repository.dart';

typedef StudentGroupEditorData = ({
  StudentGroup? group,
  List<Student> students,
});

class LoadStudentGroupEditor {
  final StudentGroupsRepository groups;
  final StudentsRepository students;
  LoadStudentGroupEditor(this.groups, this.students);
  Future<StudentGroupEditorData> call(String? id) async {
    final group = id == null ? null : await groups.get(id);
    final items = <Student>[];
    var page = 1;
    while (true) {
      final result = await students.list(page: page, status: 'active');
      items.addAll(result.items);
      if (!result.hasNext) break;
      page++;
    }
    return (group: group, students: List<Student>.unmodifiable(items));
  }
}
