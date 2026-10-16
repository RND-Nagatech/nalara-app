import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/app_failure.dart';
import '../../data/datasources/password_reset_local_source.dart';
import '../../domain/repositories/auth_repository.dart';

enum PasswordResetStep { email, otp, newPassword }

enum PasswordResetPhase { idle, loading, success, failure }

class PasswordResetState {
  final PasswordResetStep step;
  final PasswordResetPhase phase;
  final String email;
  final String resetToken;
  final int remainingSeconds;
  final String? error;
  final bool restored;

  const PasswordResetState({
    this.step = PasswordResetStep.email,
    this.phase = PasswordResetPhase.idle,
    this.email = '',
    this.resetToken = '',
    this.remainingSeconds = 0,
    this.error,
    this.restored = false,
  });

  bool get busy => phase == PasswordResetPhase.loading;
  bool get hasPendingFlow =>
      restored && email.isNotEmpty && step != PasswordResetStep.email;

  PasswordResetState copyWith({
    PasswordResetStep? step,
    PasswordResetPhase? phase,
    String? email,
    String? resetToken,
    int? remainingSeconds,
    String? error,
    bool? restored,
    bool clearError = false,
  }) => PasswordResetState(
    step: step ?? this.step,
    phase: phase ?? this.phase,
    email: email ?? this.email,
    resetToken: resetToken ?? this.resetToken,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    error: clearError ? null : error ?? this.error,
    restored: restored ?? this.restored,
  );
}

class PasswordResetCubit extends Cubit<PasswordResetState> {
  final AuthRepository _repository;
  final PasswordResetLocalSource _local;
  Timer? _timer;

  PasswordResetCubit(this._repository, this._local)
    : super(const PasswordResetState());

  bool get hasPendingFlow => state.hasPendingFlow;

  Future<void> restore() async {
    try {
      final draft = await _local.read();
      if (isClosed) return;

      if (draft == null) {
        emit(state.copyWith(restored: true));
        return;
      }

      final token = draft.resetToken;
      if (draft.step == 'new-password' && token != null && token.isNotEmpty) {
        emit(
          PasswordResetState(
            step: PasswordResetStep.newPassword,
            email: draft.email,
            resetToken: token,
            restored: true,
          ),
        );
        return;
      }

      final remaining = draft.otpExpiresAt <= 0
          ? 0
          : ((draft.otpExpiresAt - DateTime.now().millisecondsSinceEpoch) /
                    1000)
                .ceil()
                .clamp(0, 60 * 60)
                .toInt();
      emit(
        PasswordResetState(
          step: PasswordResetStep.otp,
          email: draft.email,
          remainingSeconds: remaining,
          restored: true,
        ),
      );
    } catch (_) {
      // A local restore failure must not block the user from requesting a new OTP.
      if (!isClosed) emit(state.copyWith(restored: true));
    }
  }

  String _errorMessage(Object error) => error is AppFailure
      ? error.message
      : 'Terjadi kesalahan. Silakan coba lagi.';

  Future<void> requestOtp(String email) async {
    if (state.busy) return;
    final normalizedEmail = email.trim().toLowerCase();
    emit(
      state.copyWith(
        phase: PasswordResetPhase.loading,
        email: normalizedEmail,
        clearError: true,
      ),
    );
    try {
      final expiresInSeconds = await _repository.requestPasswordReset(
        normalizedEmail,
      );
      if (isClosed) return;
      await _persistOtp(
        normalizedEmail,
        DateTime.now().add(Duration(seconds: expiresInSeconds)),
      );
      emit(
        state.copyWith(
          step: PasswordResetStep.otp,
          phase: PasswordResetPhase.idle,
          remainingSeconds: expiresInSeconds,
          restored: true,
          clearError: true,
        ),
      );
      _startCountdown(expiresInSeconds);
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: PasswordResetPhase.failure,
            error: _errorMessage(error),
          ),
        );
      }
    }
  }

  Future<void> resendOtp() async {
    if (state.busy || state.remainingSeconds > 0 || state.email.isEmpty) {
      return;
    }
    await requestOtp(state.email);
  }

  Future<void> verifyOtp(String otp) async {
    if (state.busy || state.email.isEmpty) return;
    emit(state.copyWith(phase: PasswordResetPhase.loading, clearError: true));
    try {
      final resetToken = await _repository.verifyResetOtp(
        email: state.email,
        otp: otp.trim(),
      );
      _timer?.cancel();
      await _persistNewPassword(resetToken);
      if (!isClosed) {
        emit(
          state.copyWith(
            step: PasswordResetStep.newPassword,
            phase: PasswordResetPhase.idle,
            resetToken: resetToken,
            remainingSeconds: 0,
            clearError: true,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: PasswordResetPhase.failure,
            error: _errorMessage(error),
          ),
        );
      }
    }
  }

  Future<void> resetPassword(String newPassword) async {
    if (state.busy || state.resetToken.isEmpty) return;
    emit(state.copyWith(phase: PasswordResetPhase.loading, clearError: true));
    try {
      await _repository.resetPassword(
        resetToken: state.resetToken,
        newPassword: newPassword,
      );
      await _clearPersistedFlow();
      if (!isClosed) {
        emit(
          state.copyWith(phase: PasswordResetPhase.success, clearError: true),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: PasswordResetPhase.failure,
            error: _errorMessage(error),
          ),
        );
      }
    }
  }

  Future<void> cancel() async {
    _timer?.cancel();
    if (!isClosed) {
      emit(const PasswordResetState(restored: true));
    }
    await _clearPersistedFlow();
  }

  Future<void> _persistOtp(String email, DateTime expiresAt) async {
    try {
      await _local.saveOtp(email: email, expiresAt: expiresAt);
    } catch (_) {
      // The reset request remains usable if secure storage is temporarily unavailable.
    }
  }

  Future<void> _persistNewPassword(String resetToken) async {
    try {
      await _local.saveNewPassword(email: state.email, resetToken: resetToken);
    } catch (_) {
      // The reset flow remains usable in the current session.
    }
  }

  Future<void> _clearPersistedFlow() async {
    try {
      await _local.clear();
    } catch (_) {
      // Do not block navigation after the reset flow has been completed/cancelled.
    }
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) timer.cancel();
      emit(state.copyWith(remainingSeconds: remaining.clamp(0, seconds)));
    });
  }

  String get maskedEmail {
    final parts = state.email.split('@');
    if (parts.length != 2 || parts.first.length < 3) return state.email;
    return '${parts.first.substring(0, 2)}•••@${parts.last}';
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
