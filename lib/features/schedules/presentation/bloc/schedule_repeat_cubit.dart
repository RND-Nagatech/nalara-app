import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/schedule_repeat.dart';

class ScheduleRepeatState {
  final bool enabled, autoDay;
  final ScheduleRepeat value;
  ScheduleRepeatState({
    required this.enabled,
    required this.value,
    this.autoDay = false,
  });
}

class ScheduleRepeatCubit extends Cubit<ScheduleRepeatState> {
  ScheduleRepeatCubit({ScheduleRepeat? initial, int weekday = 1})
    : super(
        ScheduleRepeatState(
          enabled: initial != null,
          value: initial ?? ScheduleRepeat(days: {weekday}),
          autoDay: initial == null,
        ),
      );
  void enable(bool enabled) => emit(
    ScheduleRepeatState(
      enabled: enabled,
      value: state.value,
      autoDay: state.autoDay,
    ),
  );
  void toggleDay(int day) {
    final days = Set<int>.of(state.value.days);
    if (!days.remove(day)) days.add(day);
    _replace(days: days, autoDay: false);
  }

  void anchorChanged(int weekday) {
    if (state.autoDay) _replace(days: {weekday});
  }

  void changeEnd(ScheduleRepeatEnd end) => _replace(end: end);
  void count(int count) => _replace(count: count);
  void until(String date) => _replace(until: date);
  void _replace({
    Set<int>? days,
    ScheduleRepeatEnd? end,
    int? count,
    String? until,
    bool? autoDay,
  }) => emit(
    ScheduleRepeatState(
      enabled: state.enabled,
      autoDay: autoDay ?? state.autoDay,
      value: ScheduleRepeat(
        days: days ?? state.value.days,
        end: end ?? state.value.end,
        count: count ?? state.value.count,
        until: until ?? state.value.until,
      ),
    ),
  );
  String? validate(String startDate) {
    if (!state.enabled) return null;
    final value = state.value;
    if (value.days.isEmpty) return 'Pilih minimal satu hari pengulangan.';
    if (value.end == ScheduleRepeatEnd.count &&
        (value.count < 1 || value.count > 52)) {
      return 'Jumlah pertemuan harus 1–52.';
    }
    if (value.end == ScheduleRepeatEnd.until &&
        (value.until == null || value.until!.compareTo(startDate) < 0)) {
      return 'Pilih tanggal akhir setelah atau sama dengan tanggal mulai.';
    }
    return null;
  }
}
