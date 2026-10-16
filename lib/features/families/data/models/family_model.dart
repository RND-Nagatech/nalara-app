import '../../domain/entities/family.dart';

class FamilyModel {
  final Map<String, dynamic> json;
  FamilyModel(this.json);
  Family toEntity() => Family(
    id: json['_id'] as String,
    parentName: json['parentName'] as String,
    parentPhone: json['parentPhone'] as String,
    version: (json['version'] as num?)?.toInt() ?? 0,
    children: List.unmodifiable(
      (json['students'] as List? ?? []).map(
        (row) => FamilyChild(
          id: row['_id'] as String,
          name: row['name'] as String,
          grade: row['grade'] as String? ?? '',
          status: row['status'] as String,
        ),
      ),
    ),
  );
}
