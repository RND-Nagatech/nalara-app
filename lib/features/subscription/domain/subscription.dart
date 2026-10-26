class TutorPlan {
  final String id, name, description;
  final int price;
  final int? studentLimit;
  final List<String> features;
  const TutorPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.studentLimit,
    required this.features,
  });
}

class TutorSubscription {
  final String? paymentSyncWarning;
  final String plan, status;
  final bool active, checkoutEnabled;
  final int daysRemaining, activeStudents, trialDays;
  final int? studentLimit;
  final DateTime endsAt, serverNow;
  final List<String> features;
  final Map<String, String> featureLabels;
  final List<TutorPlan> plans;
  const TutorSubscription({
    this.paymentSyncWarning,
    required this.plan,
    required this.status,
    required this.active,
    required this.checkoutEnabled,
    required this.daysRemaining,
    required this.activeStudents,
    required this.studentLimit,
    required this.trialDays,
    required this.endsAt,
    required this.serverNow,
    required this.features,
    required this.featureLabels,
    required this.plans,
  });
  bool has(String feature) => active && features.contains(feature);
  String get name => plan == 'trial'
      ? 'Trial Pro'
      : plan == 'pro'
      ? 'Tutor Pro'
      : 'Tutor Basic';
}

class SubscriptionPayment {
  final String id, reference, plan, status;
  final int amount;
  final String? checkoutUrl;
  final DateTime createdAt;
  const SubscriptionPayment({
    required this.id,
    required this.reference,
    required this.plan,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.checkoutUrl,
  });
  bool get paid => status == 'paid';
  bool get open => status == 'creating' || status == 'pending';
  bool get canContinue {
    final uri = Uri.tryParse(checkoutUrl ?? '');
    return open && uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}
