import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../utils/color.dart';
import '../bloc/notification_permission_cubit.dart';
import 'notification_permission_dialog.dart';

/// Use the real root navigator for focus, SafeArea, barrier and back behavior.
/// It owns only its own route; auth/payment/tutorial routes are never popped.
class NotificationPermissionHost extends StatefulWidget {
  final NotificationPermissionCubit cubit;
  final GoRouter router;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool enabled;
  final Widget child;
  const NotificationPermissionHost({
    super.key,
    required this.cubit,
    required this.router,
    required this.navigatorKey,
    required this.enabled,
    required this.child,
  });

  @override
  State<NotificationPermissionHost> createState() =>
      _NotificationPermissionHostState();
}

class _NotificationPermissionHostState
    extends State<NotificationPermissionHost> {
  StreamSubscription<NotificationPermissionState>? _subscription;
  DialogRoute<void>? _route;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.cubit.stream.listen((_) => _schedule());
    widget.router.routerDelegate.addListener(_schedule);
    if (widget.enabled) unawaited(widget.cubit.initialize());
    _schedule();
  }

  @override
  void didUpdateWidget(NotificationPermissionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled) unawaited(widget.cubit.initialize());
    _schedule();
  }

  void _schedule() {
    if (!mounted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _sync();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _sync() {
    final path = widget.router.state.uri.path;
    final visible =
        widget.enabled &&
        widget.cubit.state.visible &&
        !path.startsWith('/legal/') &&
        path != '/forgot-password';
    if (!visible) {
      _close();
      return;
    }
    final navigator = widget.navigatorKey.currentState;
    if (_route != null || navigator == null || !navigator.mounted) return;
    final cubit = widget.cubit;
    final route = DialogRoute<void>(
      context: navigator.context,
      barrierDismissible: false,
      barrierColor: NalaraColors.ink.withValues(alpha: .45),
      settings: const RouteSettings(name: 'nalara-notification-permission'),
      builder: (_) =>
          BlocBuilder<NotificationPermissionCubit, NotificationPermissionState>(
            bloc: cubit,
            builder: (context, state) => NotificationPermissionDialog(
              busy: state.busy,
              error: state.error,
              onEnable: () => unawaited(cubit.request()),
              onLater: () => unawaited(cubit.defer()),
            ),
          ),
    );
    _route = route;
    unawaited(
      navigator.push(route).then((_) {
        if (!mounted || !identical(_route, route)) return;
        _route = null;
        // Back is the same optional decision as Nanti saja, never an OS request.
        if (cubit.state.visible && !cubit.state.busy) unawaited(cubit.defer());
      }),
    );
  }

  void _close() {
    final route = _route;
    _route = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    widget.router.routerDelegate.removeListener(_schedule);
    final route = _route;
    _route = null;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
