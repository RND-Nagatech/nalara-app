import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../teaching_guide/presentation/teaching_tutorial_scope.dart';
import '../../../teaching_guide/presentation/teaching_guide_cubit.dart';

/// Profile entry shows profile omissions; Lainnya combines those with pending
/// guide milestones so that the existing tutorial indicator is not lost.
class ProfileCompletionBadge extends StatelessWidget {
  final Widget? child;
  final bool includeGuide;
  const ProfileCompletionBadge({
    super.key,
    this.child,
    this.includeGuide = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<AuthCubit>()) return _guide(context, 0);
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      builder: (context, state) => _guide(
        context,
        state.status == AuthStatus.authenticated
            ? state.teacher?.incompleteProfileCount ?? 0
            : 0,
      ),
    );
  }

  Widget _guide(BuildContext context, int profileCount) {
    final guide = includeGuide
        ? TeachingTutorialScope.maybeOf(context)?.guide
        : null;
    if (guide == null) return _badge(profileCount, 0);
    return BlocBuilder<TeachingGuideCubit, TeachingGuideState>(
      bloc: guide,
      builder: (_, state) =>
          _badge(profileCount, state.value?.remainingCount ?? 0),
    );
  }

  Widget _badge(int profileCount, int guideCount) {
    final count = profileCount + guideCount;
    if (count == 0) return child ?? const SizedBox.shrink();
    return Semantics(
      label: [
        if (profileCount > 0) '$profileCount data profil belum diisi',
        if (guideCount > 0) '$guideCount panduan belum selesai',
      ].join(', '),
      child: GuideCountBadge(count: count, child: child),
    );
  }
}
