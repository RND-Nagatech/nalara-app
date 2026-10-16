import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';

class SubscriptionState {
  final TutorSubscription? value;
  final bool loading, expired;
  final String? error, paywallFeature;
  const SubscriptionState({
    this.value,
    this.loading = false,
    this.expired = false,
    this.error,
    this.paywallFeature,
  });
  bool get blocked => expired || value?.active == false;
}

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final SubscriptionRepository repository;
  String? accountId;
  int _generation = 0;
  Timer? _expiry;
  Future<void>? _pending;
  bool _synchronizingPayment = false;
  SubscriptionCubit(this.repository) : super(const SubscriptionState());
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
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          SubscriptionState(
            value: state.value,
            expired: state.expired,
            error: error.toString(),
            paywallFeature: state.paywallFeature,
          ),
        );
      }
    }
  }

  void paywall(String code) {
    if (isClosed) return;
    emit(
      SubscriptionState(
        value: state.value,
        expired: state.expired || code == 'SUBSCRIPTION_REQUIRED',
        paywallFeature: code,
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
        ),
      );
    }
  }

  void reset() {
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
