import '../../student_groups/domain/student_group.dart';
import '../../student_groups/domain/student_groups_repository.dart';
import '../../students/domain/entities/student.dart';
import '../../subjects/domain/entities/subject.dart';
import 'load_tutor_catalog.dart';

class ActivityOptions {
  final List<Student> students;
  final List<Subject> subjects;
  final List<StudentGroup> groups;
  ActivityOptions({
    required Iterable<Student> students,
    required Iterable<Subject> subjects,
    Iterable<StudentGroup> groups = const [],
  }) : students = List.unmodifiable(students),
       subjects = List.unmodifiable(subjects),
       groups = List.unmodifiable(groups);
}

class LoadActivityOptions {
  final LoadTutorCatalog catalog;
  final StudentGroupsRepository groups;
  LoadActivityOptions(this.catalog, this.groups);
  Future<ActivityOptions> call({bool includeGroups = true}) async {
    final options = await catalog();
    final items = <StudentGroup>[];
    if (includeGroups) {
      for (var page = 1; ; page++) {
        final result = await groups.list(page: page, limit: 100);
        items.addAll(result.items);
        if (!result.hasNext) break;
      }
    }
    return ActivityOptions(
      students: options.students,
      subjects: options.subjects,
      groups: items,
    );
  }
}
