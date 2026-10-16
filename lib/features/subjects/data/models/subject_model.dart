import '../../domain/entities/subject.dart';

class SubjectModel {
  final Map<String, dynamic> json;
  SubjectModel(this.json);
  Subject toEntity() => Subject(id: json['_id'], name: json['name']);
}
