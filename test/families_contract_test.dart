import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/families/data/datasources/families_remote_source.dart';
import 'package:nalara/features/families/data/repositories/families_repository_impl.dart';
import 'package:nalara/features/families/domain/entities/family.dart';
import 'package:nalara/features/families/domain/repositories/families_repository.dart';
import 'package:nalara/features/families/domain/usecases/load_family_options.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/data/datasources/students_remote_source.dart';
import 'package:nalara/features/students/data/repositories/students_repository_impl.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';

class FamiliesStub extends FamiliesRemoteSource {
  Map<String, dynamic>? fields;
  FamiliesStub(super.api);
  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> fields) async {
    this.fields = fields;
    return {
      '_id': 'family',
      ...fields,
      'version': 0,
      'students': [
        {'_id': 'a', 'name': 'Alya', 'status': 'active'},
        {'_id': 'b', 'name': 'Bima', 'status': 'active'},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> fields) =>
      create(fields);
}

class PagedFamilies extends FamiliesRepository {
  final requestedPages = <int>[];
  @override
  Future<PageResult<Family>> list({int page = 1, String search = ''}) async {
    requestedPages.add(page);
    return PageResult(
      items: [
        Family(
          id: '$page',
          parentName: 'Ibu $page',
          parentPhone: '081234567890',
          version: 0,
          children: [],
        ),
      ],
      total: 2,
      page: page,
      limit: 1,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'family repository sends all siblings once and server optimistic version on edit',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final remote = FamiliesStub(
        ApiClient(dio, TokenStore(const FlutterSecureStorage())),
      );
      final repository = FamiliesRepositoryImpl(remote);
      final family = await repository.create(
        const FamilyDraft(
          parentName: ' Ibu Alya ',
          parentPhone: '081234567890',
          studentIds: ['a', 'b'],
        ),
      );
      expect(remote.fields, {
        'parentName': 'Ibu Alya',
        'parentPhone': '+6281234567890',
        'studentIds': ['a', 'b'],
      });
      expect(family.children.length, 2);
      await repository.update(
        family.id,
        const FamilyDraft(
          parentName: 'Ibu Alya',
          parentPhone: '081234567890',
          studentIds: ['a', 'b'],
          version: 3,
        ),
      );
      expect(remote.fields!['version'], 3);
    },
  );
  test('family selector use case loads beyond the first API page', () async {
    final repository = PagedFamilies();
    expect((await LoadFamilies(repository)()).map((f) => f.id), ['1', '2']);
    expect(repository.requestedPages, [1, 2]);
  });
  test(
    'student payload preserves omitted assignment and supports explicit detach',
    () {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final repository = StudentsRepositoryImpl(
        StudentsRemoteSource(
          ApiClient(dio, TokenStore(const FlutterSecureStorage())),
        ),
      );
      expect(
        repository
            .fields(const StudentDraft(name: 'Alya'))
            .containsKey('familyId'),
        isFalse,
      );
      expect(
        repository.fields(
          const StudentDraft(name: 'Alya', familyId: 'family'),
        )['familyId'],
        'family',
      );
      final detach = repository.fields(
        const StudentDraft(name: 'Alya', clearFamily: true),
      );
      expect(detach.containsKey('familyId'), isTrue);
      expect(detach['familyId'], isNull);
    },
  );
}
