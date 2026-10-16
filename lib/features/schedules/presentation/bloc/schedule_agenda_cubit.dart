import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/page.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_calendar.dart';
import '../../domain/entities/schedule_period.dart';
import '../../domain/usecases/load_schedule_agenda.dart';

class AgendaListState {
  final ScheduleWindow window;
  final PageResult<Lesson>? data;
  final bool loading;
  final String? error;
  final int requestedPage;
  const AgendaListState({
    required this.window,
    this.data,
    this.loading = false,
    this.error,
    this.requestedPage = 1,
  });
}

class ScheduleAgendaState {
  final DateTime date;
  final String timezone;
  final SchedulePeriod period;
  final Map<SchedulePeriod, AgendaListState> lists;
  const ScheduleAgendaState({
    required this.date,
    required this.timezone,
    this.period = SchedulePeriod.day,
    this.lists = const {},
  });
  AgendaListState? get current => lists[period];
}

class ScheduleAgendaCubit extends Cubit<ScheduleAgendaState> {
  final LoadScheduleAgenda _loadAgenda;
  final DateTime Function() _clock;
  int _sequence = 0, _generation = 0, _preferredDay = 1;
  final _tickets = <SchedulePeriod, int>{};
  ScheduleAgendaCubit(this._loadAgenda, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(
        ScheduleAgendaState(
          date: ScheduleCalendar.date((clock ?? DateTime.now)()),
          timezone: 'Asia/Jakarta',
        ),
      );
  Future<void> initialize({
    DateTime? date,
    required String timezone,
    required SchedulePeriod period,
  }) async {
    if (isClosed) return;
    _generation++;
    _tickets.clear();
    final selected = date == null
        ? ScheduleCalendar.localDate(_clock(), timezone)
        : ScheduleCalendar.date(date);
    _preferredDay = selected.day;
    emit(
      ScheduleAgendaState(date: selected, timezone: timezone, period: period),
    );
    await _load(period);
  }

  Future<void> selectPeriod(SchedulePeriod period) async {
    if (isClosed) return;
    emit(
      ScheduleAgendaState(
        date: state.date,
        timezone: state.timezone,
        period: period,
        lists: state.lists,
      ),
    );
    await _ensure(period);
  }

  Future<void> selectDate(DateTime date) => _selection(date, state.period);
  Future<void> showDay(DateTime date) => _selection(date, SchedulePeriod.day);
  bool canMove(int direction) => ScheduleCalendar.allowed(
    ScheduleCalendar.move(
      state.date,
      state.period,
      direction,
      preferredDay: _preferredDay,
    ),
  );
  Future<void> move(int direction) async {
    if (isClosed || !canMove(direction)) return;
    final date = ScheduleCalendar.move(
      state.date,
      state.period,
      direction,
      preferredDay: _preferredDay,
    );
    await _selection(
      date,
      state.period,
      updatePreferred: state.period != SchedulePeriod.month,
    );
  }

  Future<void> _selection(
    DateTime value,
    SchedulePeriod period, {
    bool updatePreferred = true,
  }) async {
    if (isClosed || !ScheduleCalendar.allowed(value)) return;
    final date = ScheduleCalendar.date(value);
    if (updatePreferred) _preferredDay = date.day;
    final retained = <SchedulePeriod, AgendaListState>{};
    for (final entry in state.lists.entries) {
      if (entry.value.window ==
          ScheduleCalendar.window(date, entry.key, state.timezone)) {
        retained[entry.key] = entry.value;
      } else {
        _tickets.remove(entry.key);
      }
    }
    emit(
      ScheduleAgendaState(
        date: date,
        timezone: state.timezone,
        period: period,
        lists: Map.unmodifiable(retained),
      ),
    );
    await _ensure(period);
  }

  Future<void> _ensure(SchedulePeriod period) async {
    final value = state.lists[period];
    if (value == null ||
        (!value.loading && (value.data == null || value.error != null))) {
      await _load(period);
    }
  }

  Future<void> refresh() async {
    if (isClosed) return;
    _generation++;
    _tickets.clear();
    final previous = state.current;
    emit(
      ScheduleAgendaState(
        date: state.date,
        timezone: state.timezone,
        period: state.period,
        lists: previous?.data == null
            ? const {}
            : Map.unmodifiable({
                state.period: AgendaListState(
                  window: previous!.window,
                  data: previous.data,
                ),
              }),
      ),
    );
    await _load(state.period);
  }

  Future<void> page(int page, {required SchedulePeriod period}) async {
    if (page < 1) return;
    await _load(period, page: page);
  }

  Future<void> loadMore(SchedulePeriod period) async {
    final data = state.lists[period]?.data;
    if (data == null || state.lists[period]?.loading == true || !data.hasNext) {
      return;
    }
    await _load(period, page: data.page + 1, append: true);
  }

  Future<void> retry(SchedulePeriod period) {
    final value = state.lists[period];
    final append =
        value?.data != null && value!.requestedPage > value.data!.page;
    return _load(period, page: value?.requestedPage ?? 1, append: append);
  }

  Future<void> _load(
    SchedulePeriod period, {
    int page = 1,
    bool append = false,
  }) async {
    if (isClosed || state.lists[period]?.loading == true) return;
    final generation = _generation, ticket = ++_sequence;
    final date = state.date, timezone = state.timezone;
    final window = ScheduleCalendar.window(date, period, timezone);
    final previous = state.lists[period]?.data;
    _tickets[period] = ticket;
    _set(
      period,
      AgendaListState(
        window: window,
        data: previous,
        loading: true,
        requestedPage: page,
      ),
    );
    bool current() =>
        !isClosed &&
        generation == _generation &&
        _tickets[period] == ticket &&
        ScheduleCalendar.window(state.date, period, state.timezone) == window;
    try {
      final data = await _loadAgenda(
        date: date,
        period: period,
        timezone: timezone,
        page: page,
      );
      if (current()) {
        final loaded = append && previous != null
            ? PageResult<Lesson>(
                items: List.unmodifiable([...previous.items, ...data.items]),
                total: data.total,
                page: data.page,
                limit: data.limit,
              )
            : data;
        _set(
          period,
          AgendaListState(
            window: window,
            data: loaded,
            requestedPage: loaded.page,
          ),
        );
      }
    } catch (error) {
      if (current()) {
        _set(
          period,
          AgendaListState(
            window: window,
            data: previous,
            error: error.toString(),
            requestedPage: page,
          ),
        );
      }
    }
  }

  void _set(SchedulePeriod period, AgendaListState value) => emit(
    ScheduleAgendaState(
      date: state.date,
      timezone: state.timezone,
      period: state.period,
      lists: Map.unmodifiable({...state.lists, period: value}),
    ),
  );
  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
