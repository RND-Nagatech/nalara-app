import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_permission_repository.dart';

enum NotificationPromptPhase { checking, hidden, offer, requesting }

class NotificationPermissionState {
  final NotificationPromptPhase phase;
  final NotificationPermissionStatus status;
  final String? error;
  const NotificationPermissionState({
    this.phase = NotificationPromptPhase.checking,
    this.status = NotificationPermissionStatus.unavailable,
    this.error,
  });
  bool get visible =>
      phase == NotificationPromptPhase.offer ||
      phase == NotificationPromptPhase.requesting;
  bool get busy => phase == NotificationPromptPhase.requesting;
  bool get blocksTutorial =>
      phase == NotificationPromptPhase.checking || visible;
}

/// This is a device/origin decision, not an account's notification preference.
class NotificationPermissionCubit extends Cubit<NotificationPermissionState> {
  final NotificationPermissionRepository repository;
  bool _initialized = false;
  bool _dismissed = false;
  int _revision = 0;
  NotificationPermissionCubit(this.repository)
    : super(const NotificationPermissionState());

  Future<void> initialize() async {
    if (_initialized || isClosed) return;
    _initialized = true;
    final revision = ++_revision;
    try {
      final prompted = await repository.wasPrompted();
      final status = await repository.status();
      if (isClosed || revision != _revision) return;
      _dismissed = prompted;
      final eligible = _canOffer(status);
      emit(
        NotificationPermissionState(
          status: status,
          phase: !prompted && eligible
              ? NotificationPromptPhase.offer
              : NotificationPromptPhase.hidden,
        ),
      );
    } catch (_) {
      // An unavailable provider/storage must not block onboarding or login.
      if (!isClosed && revision == _revision) {
        emit(
          const NotificationPermissionState(
            phase: NotificationPromptPhase.hidden,
          ),
        );
      }
    }
  }

  Future<void> defer() async {
    if (isClosed || state.busy || !state.visible) return;
    _revision++;
    _dismissed = true;
    emit(
      NotificationPermissionState(
        phase: NotificationPromptPhase.hidden,
        status: state.status,
      ),
    );
    await _remember();
  }

  Future<void> request() async {
    if (isClosed || state.busy || !state.visible) return;
    _revision++;
    final previous = state.status;
    emit(
      NotificationPermissionState(
        phase: NotificationPromptPhase.requesting,
        status: previous,
      ),
    );
    try {
      // No awaited work before this call: preserve the browser's user gesture.
      final status = await repository.request();
      _dismissed = true;
      await _remember();
      if (isClosed) return;
      emit(
        NotificationPermissionState(
          phase: NotificationPromptPhase.hidden,
          status: status,
        ),
      );
      if (status.granted) await repository.synchronizeRegistration();
    } catch (_) {
      if (!isClosed && !_dismissed) {
        emit(
          NotificationPermissionState(
            phase: NotificationPromptPhase.offer,
            status: previous,
            error:
                'Notifikasi belum bisa diaktifkan. Coba lagi atau pilih Nanti saja.',
          ),
        );
      }
    }
  }

  Future<void> refresh() async {
    if (isClosed ||
        !_initialized ||
        state.busy ||
        state.phase == NotificationPromptPhase.checking) {
      return;
    }
    final revision = ++_revision;
    try {
      final status = await repository.status();
      if (isClosed || state.busy || revision != _revision) return;
      emit(
        NotificationPermissionState(
          status: status,
          phase: !_canOffer(status) || _dismissed
              ? NotificationPromptPhase.hidden
              : state.phase,
        ),
      );
    } catch (_) {
      /* Silent resume checks never interrupt the application. */
    }
  }

  bool _canOffer(NotificationPermissionStatus status) =>
      status == NotificationPermissionStatus.notDetermined ||
      (status == NotificationPermissionStatus.denied &&
          repository.canRequestWhenDenied);

  Future<void> _remember() async {
    try {
      await repository.rememberPrompt();
    } catch (_) {
      // Keep the choice in memory even if device storage is temporarily locked.
    }
  }
}
