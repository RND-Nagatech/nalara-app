import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/teaching_guide/data/teaching_guide_model.dart';
import 'package:nalara/features/teaching_guide/data/teaching_guide_remote_source.dart';
import 'package:nalara/features/teaching_guide/data/teaching_guide_repository_impl.dart';
import 'package:nalara/features/teaching_guide/domain/teaching_guide.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_guide_cubit.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/constants.dart';
import 'teaching_guide_fixtures.dart';

Map<String, dynamic> _json() => {
  'dismissed': false,
  'hasSubject': true,
  'hasStudent': true,
  'hasSchedule': false,
  'hasTarget': false,
  'parentConnected': false,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'steps follow stored data, parent access is optional and old data counts',
    () {
      final empty = guideValue();
      expect(empty.completedCount, 0);
      expect(empty.nextStep, TeachingGuideStep.subject);
      final partial = guideValue(subject: true, student: true);
      expect(partial.completedCount, 2);
      expect(partial.nextStep, TeachingGuideStep.schedule);
      final existing = guideValue(
        subject: true,
        student: true,
        schedule: true,
        target: true,
      );
      expect(existing.isComplete, isTrue);
      expect(existing.parentConnected, isFalse);
      expect(existing.nextStep, isNull);
      expect(partial.withDismissed(true).completedCount, 2);
    },
  );

  test(
    'missing and invalid API flags are errors, not invented incomplete steps',
    () {
      for (final name in _json().keys) {
        for (final invalid in [null, 0, 'false']) {
          expect(
            () => TeachingGuideModel(_json()..[name] = invalid).toEntity(),
            throwsA(
              isA<AppFailure>().having(
                (e) => e.code,
                'code',
                'INVALID_RESPONSE',
              ),
            ),
          );
        }
      }
      expect(TeachingGuideModel(_json()).toEntity().completedCount, 2);
    },
  );

  test(
    'remote source uses central endpoints and sends only dismissal preference',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': options.method == 'PATCH'
                      ? {'dismissed': true}
                      : _json(),
                },
              ),
            );
          },
        ),
      );
      final tokens = TokenStore(const FlutterSecureStorage())
        ..accessToken = 'teacher-token';
      final repo = TeachingGuideRepositoryImpl(
        TeachingGuideRemoteSource(ApiClient(dio, tokens)),
      );
      expect((await repo.get()).nextStep, TeachingGuideStep.schedule);
      expect(await repo.setDismissed(true), isTrue);
      expect(requests.first.path, ApiConstants.teachingGuide);
      expect(requests.last.path, ApiConstants.teachingGuidePreferences);
      expect(requests.last.data, {'dismissed': true});
      expect(requests.first.headers['Authorization'], 'Bearer teacher-token');
    },
  );

  test(
    'recreating the cubit restores server progress and skip preference',
    () async {
      final repo = TeachingGuideFake(guideValue(subject: true, student: true));
      final first = TeachingGuideCubit(repo);
      await first.load();
      await first.setDismissed(true);
      await first.close();
      final restored = TeachingGuideCubit(repo);
      await restored.load();
      expect(restored.state.value!.dismissed, isTrue);
      expect(restored.state.value!.nextStep, TeachingGuideStep.schedule);
      await restored.close();
    },
  );

  test(
    'failed reads preserve data and show backend errors, initial failure has no progress',
    () async {
      final repo = TeachingGuideFake(guideValue(subject: true));
      final cubit = TeachingGuideCubit(repo);
      await cubit.load();
      repo.loadError = const AppFailure('Panduan sedang tidak tersedia.');
      await cubit.load();
      expect(cubit.state.value!.hasSubject, isTrue);
      expect(cubit.state.error, 'Panduan sedang tidak tersedia.');
      final fresh = TeachingGuideCubit(repo);
      await fresh.load();
      expect(fresh.state.value, isNull);
      await cubit.close();
      await fresh.close();
    },
  );

  test(
    'failed skip never hides the guide and duplicate saves are ignored',
    () async {
      final repo = TeachingGuideFake(guideValue())
        ..saveError = const AppFailure('Pilihan belum tersimpan.');
      final cubit = TeachingGuideCubit(repo);
      await cubit.load();
      await cubit.setDismissed(true);
      expect(cubit.state.value!.dismissed, isFalse);
      expect(cubit.state.error, 'Pilihan belum tersimpan.');
      repo.saveError = null;
      repo.pendingSave = Completer<bool>();
      final save = cubit.setDismissed(true);
      await cubit.setDismissed(false);
      expect(repo.saves, [true, true]);
      repo.pendingSave!.complete(true);
      await save;
      expect(cubit.state.value!.dismissed, isTrue);
      await cubit.close();
    },
  );

  test(
    'late reads and completion after close cannot overwrite newer state',
    () async {
      final old = Completer<TeachingGuide>(),
          latest = Completer<TeachingGuide>();
      final repo = TeachingGuideFake(guideValue())
        ..pendingReads.addAll([old, latest]);
      final cubit = TeachingGuideCubit(repo);
      final first = cubit.load(), second = cubit.load();
      latest.complete(guideValue(subject: true));
      await second;
      old.complete(guideValue());
      await first;
      expect(cubit.state.value!.hasSubject, isTrue);
      final afterClose = Completer<TeachingGuide>();
      repo.pendingReads.add(afterClose);
      final pending = cubit.load();
      await cubit.close();
      afterClose.complete(guideValue(student: true));
      await pending;
      expect(cubit.state.value!.hasSubject, isTrue);
    },
  );

  test(
    'refresh during skip waits until preference is saved and then gets current progress',
    () async {
      final repo = TeachingGuideFake(guideValue())
        ..pendingSave = Completer<bool>();
      final cubit = TeachingGuideCubit(repo);
      await cubit.load();
      final save = cubit.setDismissed(true);
      repo.value = guideValue(subject: true);
      await cubit.load();
      expect(repo.reads, 1);
      repo.pendingSave!.complete(true);
      await save;
      expect(repo.reads, 2);
      expect(cubit.state.value!.dismissed, isTrue);
      expect(cubit.state.value!.hasSubject, isTrue);
      await cubit.close();
    },
  );
}
