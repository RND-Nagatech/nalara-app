import '../../../shared/domain/page.dart';
import '../../../shared/network/api_client.dart';
import '../../../utils/constants.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';

class SubscriptionRemoteSource {
  final ApiClient api;
  SubscriptionRemoteSource(this.api);
  Future<Map<String, dynamic>> current() =>
      api.get(ApiConstants.subscriptionCurrent);
  Future<Map<String, dynamic>> synchronize() =>
      api.post(ApiConstants.subscriptionSync, {});
  Future<Map<String, dynamic>> checkout(String plan) =>
      api.post(ApiConstants.subscriptionCheckout, {'plan': plan});
  Future<Map<String, dynamic>> payments(int page) => api.get(
    ApiConstants.subscriptionPayments,
    query: {'page': page, 'limit': 10},
  );
  Future<Map<String, dynamic>> refresh(String id) =>
      api.post(ApiConstants.subscriptionPaymentRefresh(id), {});
}

SubscriptionPayment _payment(Map<String, dynamic> j) => SubscriptionPayment(
  id: j['_id'] as String,
  reference: j['reference'] as String,
  plan: j['plan'] as String,
  status: j['status'] as String,
  amount: (j['amount'] as num).toInt(),
  createdAt: DateTime.parse(j['createdAt'] as String),
  checkoutUrl: j['checkoutUrl'] as String?,
);

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteSource source;
  SubscriptionRepositoryImpl(this.source);
  @override
  Future<TutorSubscription> current() async =>
      _subscription(await source.current());
  @override
  Future<TutorSubscription> synchronize() async =>
      _subscription(await source.synchronize());

  TutorSubscription _subscription(Map<String, dynamic> j) {
    return TutorSubscription(
      paymentSyncWarning: j['paymentSyncWarning'] as String?,
      plan: j['plan'] as String,
      status: j['status'] as String,
      active: j['active'] == true,
      checkoutEnabled: j['checkoutEnabled'] == true,
      daysRemaining: (j['daysRemaining'] as num).toInt(),
      activeStudents: (j['activeStudents'] as num).toInt(),
      studentLimit: (j['studentLimit'] as num?)?.toInt(),
      trialDays: (j['trialDays'] as num).toInt(),
      endsAt: DateTime.parse(j['endsAt'] as String),
      serverNow: DateTime.parse(j['serverNow'] as String),
      features: List<String>.from(j['features'] as List),
      featureLabels: Map<String, String>.from(j['featureLabels'] as Map),
      plans: (j['plans'] as List).map((value) {
        final p = Map<String, dynamic>.from(value as Map);
        return TutorPlan(
          id: p['id'] as String,
          name: p['name'] as String,
          description: p['description'] as String,
          price: (p['price'] as num).toInt(),
          studentLimit: (p['studentLimit'] as num?)?.toInt(),
          features: List<String>.from(p['features'] as List),
        );
      }).toList(),
    );
  }

  @override
  Future<SubscriptionPayment> checkout(String plan) async =>
      _payment(await source.checkout(plan));
  @override
  Future<PageResult<SubscriptionPayment>> payments(int page) async {
    final j = await source.payments(page);
    return PageResult(
      items: (j['items'] as List)
          .map((v) => _payment(Map<String, dynamic>.from(v as Map)))
          .toList(),
      total: (j['total'] as num).toInt(),
      page: (j['page'] as num).toInt(),
      limit: (j['limit'] as num).toInt(),
    );
  }

  @override
  Future<SubscriptionPayment> refreshPayment(String id) async =>
      _payment(await source.refresh(id));
  @override
  Future<void> cancelPayment(String id) async {
    await source.api.post(ApiConstants.subscriptionPaymentCancel(id), {});
  }
}
