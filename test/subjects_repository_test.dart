import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/subjects/data/datasources/subjects_remote_source.dart';
import 'package:nalara/features/subjects/data/repositories/subjects_repository_impl.dart';
import 'package:nalara/shared/domain/teaching_catalog_changes.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';

class CatalogApi extends ApiClient {
  CatalogApi() : super(Dio(), TokenStore(const FlutterSecureStorage()));

  String? method, path;
  Map<String, dynamic>? body;
  bool fail = false;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    method = 'GET';
    this.path = path;
    return {'_id': 'subject-1', 'name': 'Piano'};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> data,
  ) async {
    method = 'PATCH';
    this.path = path;
    body = data;
    if (fail) {
      throw const AppFailure(
        'Nama bidang belajar sudah digunakan.',
        code: 'CONFLICT',
      );
    }
    return {'_id': 'subject-1', 'name': data['name']};
  }
}

void main() {
  late CatalogApi api;
  late TeachingCatalogChanges changes;
  late SubjectsRepositoryImpl repository;

  setUp(() {
    api = CatalogApi();
    changes = TeachingCatalogChanges();
    repository = SubjectsRepositoryImpl(
      SubjectsRemoteSource(api),
      changes: changes,
    );
  });

  tearDown(() async {
    await changes.close();
    api.dio.close(force: true);
  });

  test('detail loads the canonical name without announcing a write', () async {
    var events = 0;
    final subscription = changes.stream.listen((_) => events++);
    final subject = await repository.get('subject-1');
    await Future<void>.delayed(Duration.zero);
    expect(subject.name, 'Piano');
    expect(api.method, 'GET');
    expect(api.path, '/subjects/subject-1');
    expect(events, 0);
    await subscription.cancel();
  });

  test(
    'rename keeps the same ID, trims the name and invalidates retained views',
    () async {
      var events = 0;
      final subscription = changes.stream.listen((_) => events++);
      final subject = await repository.update('subject-1', '  Piano Dasar  ');
      await Future<void>.delayed(Duration.zero);
      expect(subject.id, 'subject-1');
      expect(subject.name, 'Piano Dasar');
      expect(api.method, 'PATCH');
      expect(api.path, '/subjects/subject-1');
      expect(api.body, {'name': 'Piano Dasar'});
      expect(events, 1);
      await subscription.cancel();
    },
  );

  test(
    'a rejected rename preserves the backend message and does not invalidate',
    () async {
      api.fail = true;
      var events = 0;
      final subscription = changes.stream.listen((_) => events++);
      await expectLater(
        repository.update('subject-1', 'Duplikat'),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.message,
            'message',
            'Nama bidang belajar sudah digunakan.',
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, 0);
      await subscription.cancel();
    },
  );
}
