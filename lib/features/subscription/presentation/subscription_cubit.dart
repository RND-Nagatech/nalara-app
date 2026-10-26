import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';
import '../domain/payment_celebrations.dart';

class SubscriptionState {
  final TutorSubscription? value;
  final bool loading, expired;
  final String? error, paywallFeature;
  final SubscriptionPayment? confirmedPayment;
  const SubscriptionState({
    this.value,
    this.loading = false,
    this.expired = false,
    this.error,
    this.paywallFeature,
    this.confirmedPayment,
  });
  bool get blocked => expired || value?.active == false;
}

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final SubscriptionRepository repository;
  final PaymentCelebrations? celebrations;
  String? accountId;
  int _accountGeneration = 0;
  int get accountGeneration => _accountGeneration;
  int _generation = 0;
  Timer? _expiry;
  Future<void>? _pending;
  bool _synchronizingPayment = false;
  SubscriptionCubit(this.repository, {this.celebrations})
    : super(const SubscriptionState());
  Future<void> activate(String id) {
    if (accountId != id) {
      reset();
      accountId = id;
    }
    return refresh(synchronizePayment: true);
  }

  Future<void> refresh({bool synchronizePayment = false}) {
    if (_pending != null && (!synchronizePayment || _synchronizingPayment)) {
      return _pending!;
    }
    final account = accountId;
    // A payment synchronization supersedes an older GET. Its generation guard
    // prevents the late Trial response from replacing the verified paid plan.
    final pending = _load(synchronizePayment: synchronizePayment);
    _pending = pending;
    _synchronizingPayment = synchronizePayment;
    return pending.whenComplete(() {
      if (accountId == account && identical(_pending, pending)) {
        _pending = null;
        _synchronizingPayment = false;
      }
    });
  }

  Future<void> _load({required bool synchronizePayment}) async {
    if (isClosed || accountId == null) return;
    final generation = ++_generation;
    emit(
      SubscriptionState(
        value: state.value,
        loading: true,
        expired: state.expired,
        paywallFeature: state.paywallFeature,
        confirmedPayment: state.confirmedPayment,
      ),
    );
    try {
      final value = await (synchronizePayment
          ? repository.synchronize()
          : repository.current());
      if (isClosed || generation != _generation) return;
      _expiry?.cancel();
      emit(
        SubscriptionState(
          value: value,
          expired: !value.active,
          error: value.paymentSyncWarning,
          confirmedPayment: state.confirmedPayment,
        ),
      );
      final remaining = value.endsAt.difference(value.serverNow);
      if (value.active) {
        _expiry = Timer(remaining.isNegative ? Duration.zero : remaining, () {
          if (isClosed) return;
          emit(SubscriptionState(value: state.value, expired: true));
          unawaited(refresh(synchronizePayment: true));
        });
      }
      if (synchronizePayment && celebrations != null) {
        await _findCelebration(generation, value);
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          SubscriptionState(
            value: state.value,
            expired: state.expired,
            error: error.toString(),
            paywallFeature: state.paywallFeature,
            confirmedPayment: state.confirmedPayment,
          ),
        );
      }
    }
  }

  Future<void> _findCelebration(int generation, TutorSubscription value) async {
    final account = accountId;
    if (account == null || state.confirmedPayment != null) return;
    try {
      final payment = await celebrations!.find(account, value);
      if (isClosed || generation != _generation || payment == null) return;
      emit(
        SubscriptionState(
          value: state.value,
          expired: state.expired,
          loading: state.loading,
          error: state.error,
          paywallFeature: state.paywallFeature,
          confirmedPayment: payment,
        ),
      );
    } catch (_) {
      // Cosmetic receipt/history failure must not revoke a verified plan.
      // The next synchronization retries; do not invent a paid status.
    }
  }

  Future<void> watchPayment(SubscriptionPayment payment) async {
    final account = accountId, epoch = _accountGeneration;
    if (isClosed || account == null || celebrations == null) return;
    try {
      await celebrations!.watch(account, payment);
    } catch (_) {
      // Checkout and access must remain usable if local storage is unavailable.
    }
    if (!isClosed && epoch == _accountGeneration && payment.paid) {
      await refresh(synchronizePayment: true);
    }
  }

  void dismissPayment(String paymentId) {
    final account = accountId;
    if (isClosed ||
        account == null ||
        state.confirmedPayment?.id != paymentId) {
      return;
    }
    unawaited(
      celebrations?.acknowledge(account, paymentId).catchError((Object _) {}) ??
          Future<void>.value(),
    );
    emit(
      SubscriptionState(
        value: state.value,
        expired: state.expired,
        loading: state.loading,
        error: state.error,
        paywallFeature: state.paywallFeature,
      ),
    );
  }

  void paywall(String code) {
    if (isClosed) return;
    emit(
      SubscriptionState(
        value: state.value,
        expired: state.expired || code == 'SUBSCRIPTION_REQUIRED',
        paywallFeature: code,
        confirmedPayment: state.confirmedPayment,
      ),
    );
  }

  void clearPaywall() {
    if (!isClosed) {
      emit(
        SubscriptionState(
          value: state.value,
          expired: state.expired,
          loading: state.loading,
          error: state.error,
          confirmedPayment: state.confirmedPayment,
        ),
      );
    }
  }

  void reset() {
    ++_accountGeneration;
    ++_generation;
    _expiry?.cancel();
    _pending = null;
    _synchronizingPayment = false;
    accountId = null;
    if (!isClosed) emit(const SubscriptionState());
  }

  @override
  Future<void> close() {
    ++_generation;
    _expiry?.cancel();
    return super.close();
  }
}
