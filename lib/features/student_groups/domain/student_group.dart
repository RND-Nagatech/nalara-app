import '../../students/domain/entities/student.dart';

class StudentGroup {
  final String id, name;
  final int version;
  final List<String> studentIds;
  final List<Student> students;

  StudentGroup({
    required this.id,
    required this.name,
    required this.version,
    required List<String> studentIds,
    required List<Student> students,
  }) : studentIds = List.unmodifiable(studentIds),
       students = List.unmodifiable(students);

  Set<String> activeMemberIds(Iterable<Student> available) {
    final active = available
        .where((s) => s.status == 'active')
        .map((s) => s.id)
        .toSet();
    return studentIds.where(active.contains).toSet();
  }
}
