import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/notifications/domain/entities/notification.dart';
import 'package:nalara/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'notifications_fixtures.dart';

void main() {
  late NotificationsFake repository;
  late NotificationsCubit cubit;
  setUp(() {
    repository = NotificationsFake();
    cubit = NotificationsCubit(repository);
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test(
    'server pagination snapshots stay immutable and reload uses the current page',
    () async {
      repository.records = List.generate(
        3,
        (index) => notificationFixture('$index'),
      );
      repository.limit = 2;
      await cubit.reload();
      expect(cubit.state.result!.total, 3);
      expect(cubit.state.result!.items.map((item) => item.id), ['0', '1']);
      expect(() => cubit.state.result!.items.clear(), throwsUnsupportedError);
      await cubit.goToPage(2);
      expect(cubit.state.result!.items.single.id, '2');
      await cubit.reload();
      expect(repository.pages, [1, 2, 2]);
      await cubit.goToPage(3);
      expect(repository.pages, [1, 2, 2]);
    },
  );

  test(
    'empty is only a successful zero-total response, not loading or error',
    () async {
      final response = Completer<PageResult<TeacherNotification>>();
      repository.respond = (_) => response.future;
      final request = cubit.reload();
      expect(cubit.state.loading, isTrue);
      expect(cubit.state.isEmpty, isFalse);
      response.complete(
        const PageResult(items: [], total: 0, page: 1, limit: 20),
      );
      await request;
      expect(cubit.state.isEmpty, isTrue);
      repository.respond = null;
      repository.listError = const AppFailure('Koneksi gagal');
      await cubit.reload();
      expect(cubit.state.error, 'Koneksi gagal');
      expect(cubit.state.isEmpty, isFalse);
    },
  );

  test(
    'mark read waits for server success and prevents duplicate or cross-card writes',
    () async {
      repository.records = [
        notificationFixture('one'),
        notificationFixture('two'),
      ];
      repository.readGate = Completer<void>();
      await cubit.reload();
      final save = cubit.markRead('one');
      expect(cubit.state.busyId, 'one');
      expect(cubit.state.result!.items.first.read, isFalse);
      expect(await cubit.markRead('one'), isFalse);
      expect(await cubit.markRead('two'), isFalse);
      await cubit.reload();
      expect(repository.pages, [1]);
      repository.readGate!.complete();
      expect(await save, isTrue);
      expect(cubit.state.result!.items.first.read, isTrue);
      expect(cubit.state.result!.items.last.read, isFalse);
      expect(await cubit.markRead('one'), isTrue);
      expect(await cubit.markRead('unknown'), isFalse);
      expect(repository.reads, ['one']);
    },
  );

  test(
    'read failures retain unread status and verbatim error on the affected item',
    () async {
      repository.records = [notificationFixture('one')];
      repository.readError = const AppFailure(
        'Notifikasi tidak dapat diperbarui',
      );
      await cubit.reload();
      expect(await cubit.markRead('one'), isFalse);
      expect(cubit.state.result!.items.single.read, isFalse);
      expect(cubit.state.actionErrorId, 'one');
      expect(cubit.state.actionError, 'Notifikasi tidak dapat diperbarui');
      expect(cubit.state.busyId, isNull);
      repository.readError = null;
      expect(await cubit.markRead('one'), isTrue);
    },
  );

  test(
    'failed pagination retains data and retries the requested page',
    () async {
      repository.records = [
        notificationFixture('one'),
        notificationFixture('two'),
      ];
      repository.limit = 1;
      await cubit.reload();
      repository.listError = const AppFailure('Halaman gagal dimuat');
      await cubit.goToPage(2);
      expect(cubit.state.result!.page, 1);
      expect(cubit.state.requestedPage, 2);
      expect(cubit.state.canInteract, isFalse);
      repository.listError = null;
      await cubit.reload();
      expect(cubit.state.result!.page, 2);
      expect(repository.pages, [1, 2, 2]);
    },
  );

  test(
    'stale reload responses and disposed write completions cannot replace state',
    () async {
      final old = Completer<PageResult<TeacherNotification>>();
      final latest = Completer<PageResult<TeacherNotification>>();
      repository.respond = (_) =>
          repository.pages.length == 1 ? old.future : latest.future;
      final first = cubit.reload();
      final second = cubit.reload();
      latest.complete(
        PageResult(
          items: [notificationFixture('latest')],
          total: 1,
          page: 1,
          limit: 20,
        ),
      );
      await second;
      old.complete(const PageResult(items: [], total: 0, page: 1, limit: 20));
      await first;
      expect(cubit.state.result!.items.single.id, 'latest');
      repository.readGate = Completer<void>();
      final save = cubit.markRead('latest');
      await cubit.close();
      repository.readGate!.complete();
      expect(await save, isFalse);
    },
  );
}
