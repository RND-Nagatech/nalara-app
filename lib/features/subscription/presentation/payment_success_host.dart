import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment_success_sheet.dart';
import 'subscription_cubit.dart';

/// Above the router, so leaving checkout never loses the confirmation sheet.
class PaymentSuccessHost extends StatelessWidget {
  final SubscriptionCubit subscription;
  final String? teacherId;
  final Widget child;
  const PaymentSuccessHost({
    super.key,
    required this.subscription,
    required this.teacherId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionCubit, SubscriptionState>(
        bloc: subscription,
        builder: (context, state) {
          final payment = state.confirmedPayment;
          final visible =
              teacherId != null &&
              teacherId == subscription.accountId &&
              !state.blocked &&
              payment != null;
          var planName = payment?.plan == 'pro' ? 'Pro' : 'Basic';
          for (final plan in state.value?.plans ?? []) {
            if (plan.id == payment?.plan) planName = plan.name;
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (visible)
                Positioned.fill(
                  child: BlockSemantics(
                    child: PaymentSuccessSheet(
                      key: ValueKey('$teacherId/${payment.id}'),
                      planName: planName,
                      onDismiss: () => subscription.dismissPayment(payment.id),
                    ),
                  ),
                ),
            ],
          );
        },
      );
}
