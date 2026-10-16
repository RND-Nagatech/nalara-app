import '../../domain/entities/teacher.dart';

class TeacherModel {
  final Map<String, dynamic> json;
  TeacherModel(this.json);
  Teacher toEntity() => Teacher(
    id: json['_id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    workspaceId: json['workspaceId'] as String,
    timezone: json['timezone'] as String? ?? 'Asia/Jakarta',
  );
}
