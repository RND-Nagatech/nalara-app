import '../../../shared/domain/page.dart';
import 'subscription.dart';

abstract interface class SubscriptionRepository {
  Future<TutorSubscription> current();
  Future<TutorSubscription> synchronize();
  Future<SubscriptionPayment> checkout(String plan);
  Future<PageResult<SubscriptionPayment>> payments(int page);
  Future<SubscriptionPayment> refreshPayment(String id);
  Future<void> cancelPayment(String id);
}
