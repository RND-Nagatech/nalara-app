import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/shared/state/load_cubit.dart';

void main() {
  test('loading then success', () async {
    final cubit = LoadCubit<int>(() async => 7);
    final states = <LoadStatus>[];
    final stream = cubit.stream.listen((state) => states.add(state.status));
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(states, [LoadStatus.loading, LoadStatus.success]);
    expect(cubit.state.value, 7);
    await stream.cancel();
    await cubit.close();
  });
  test('empty and errors are distinct', () async {
    final empty = LoadCubit<List<int>>(
      () async => [],
      isEmpty: (items) => items.isEmpty,
    );
    await empty.load();
    expect(empty.state.status, LoadStatus.empty);
    await empty.close();
    final error = LoadCubit<int>(() async => throw Exception('offline'));
    await error.load();
    expect(error.state.status, LoadStatus.error);
    expect(error.state.error, contains('offline'));
    await error.close();
  });
  test('old responses cannot overwrite newer loads', () async {
    final first = Completer<int>();
    var calls = 0;
    final cubit = LoadCubit<int>(
      () => ++calls == 1 ? first.future : Future.value(2),
    );
    final pending = cubit.load();
    await cubit.load();
    first.complete(1);
    await pending;
    expect(cubit.state.value, 2);
    await cubit.close();
  });
  test('submit prevents double actions and exposes errors', () async {
    final pending = Completer<void>();
    final cubit = SubmitCubit();
    var calls = 0;
    final first = cubit.run(() {
      calls++;
      return pending.future;
    });
    expect(
      await cubit.run(() async {
        calls++;
      }),
      isFalse,
    );
    expect(calls, 1);
    pending.complete();
    expect(await first, isTrue);
    expect(await cubit.run(() async => throw Exception('failure')), isFalse);
    expect(cubit.state.error, contains('failure'));
    await cubit.close();
  });
}
