import '../../students/data/models/student_model.dart';
import '../domain/student_group.dart';

class StudentGroupModel {
  final Map<String, dynamic> json;
  StudentGroupModel(this.json);
  StudentGroup toEntity() => StudentGroup(
    id: json['_id'] as String,
    name: json['name'] as String,
    version: json['version'] as int,
    studentIds: List<String>.from(json['studentIds'] as List),
    students: (json['students'] as List)
        .map((row) => StudentModel(Map<String, dynamic>.from(row)).toEntity())
        .toList(),
  );
}
