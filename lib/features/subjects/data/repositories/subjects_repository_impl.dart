import '../../../../shared/domain/page.dart';
import '../../../../shared/domain/teaching_catalog_changes.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subjects_repository.dart';
import '../datasources/subjects_remote_source.dart';
import '../models/subject_model.dart';

class SubjectsRepositoryImpl implements SubjectsRepository {
  final SubjectsRemoteSource remote;
  final TeachingCatalogChanges? changes;
  SubjectsRepositoryImpl(this.remote, {this.changes});
  @override
  Future<PageResult<Subject>> list({int page = 1}) async {
    final json = await remote.list(page);
    return PageResult(
      items: (json['items'] as List)
          .map((e) => SubjectModel(Map<String, dynamic>.from(e)).toEntity())
          .toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
    );
  }

  @override
  Future<Subject> create(String name) async {
    final subject = SubjectModel(await remote.create(name)).toEntity();
    changes?.notifyChanged();
    return subject;
  }

  @override
  Future<Subject> get(String id) async =>
      SubjectModel(await remote.get(id)).toEntity();

  @override
  Future<Subject> update(String id, String name) async {
    final subject = SubjectModel(await remote.update(id, name)).toEntity();
    changes?.notifyChanged();
    return subject;
  }
}
