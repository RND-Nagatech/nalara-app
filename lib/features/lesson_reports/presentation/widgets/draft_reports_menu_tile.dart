import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/domain/teaching_catalog_changes.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../utils/color.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../profile/presentation/widgets/more_menu_tile.dart';
import '../../../subscription/presentation/subscription_cubit.dart';
import '../../domain/repositories/reports_repository.dart';

/// Teacher-only indicator. Never derives a total from a visible report page.
class DraftReportsMenuTile extends StatefulWidget {
  final MoreMenuItem item;
  final ValueChanged<String> onOpen;
  const DraftReportsMenuTile({
    super.key,
    required this.item,
    required this.onOpen,
  });

  @override
  State<DraftReportsMenuTile> createState() => _DraftReportsMenuTileState();
}

class _DraftReportsMenuTileState extends State<DraftReportsMenuTile>
    with WidgetsBindingObserver {
  LoadCubit<int>? _count;
  ReportsRepository? _repository;
  AuthCubit? _auth;
  SubscriptionCubit? _subscription;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<SubscriptionState>? _subscriptionListener;
  StreamSubscription<void>? _changesSubscription;
  GoRouter? _router;
  (String, String)? _account;
  bool _visible = false, _dirty = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!getIt.isRegistered<AuthCubit>() ||
        !getIt.isRegistered<ReportsRepository>()) {
      return;
    }
    _repository = getIt<ReportsRepository>();
    _auth = getIt<AuthCubit>();
    if (getIt.isRegistered<SubscriptionCubit>()) {
      _subscription = getIt<SubscriptionCubit>();
      _subscriptionListener = _subscription!.stream.listen(
        (_) => _sessionChanged(),
      );
    }
    _bindAccount(_auth!.state);
    _authSubscription = _auth!.stream.listen(_sessionChanged);
    if (getIt.isRegistered<TeachingCatalogChanges>()) {
      _changesSubscription = getIt<TeachingCatalogChanges>().stream.listen((_) {
        _dirty = true;
        if (mounted && _visible) _reload();
      });
    }
  }

  void _sessionChanged([AuthState? state]) {
    if (!mounted || !_bindAccount(state ?? _auth!.state)) return;
    setState(() {});
    if (_visible) _reload();
  }

  bool _bindAccount(AuthState state) {
    final teacher = state.teacher;
    final subscription = _subscription;
    final allowed =
        subscription == null ||
        (subscription.accountId == teacher?.id &&
            subscription.state.value != null &&
            !subscription.state.blocked);
    final account =
        state.status == AuthStatus.authenticated && teacher != null && allowed
        ? (teacher.id, teacher.workspaceId)
        : null;
    if (_account == account) return false;
    // Closing the old loader invalidates late results, including logout/login
    // to the same teacher before another frame can render.
    _count?.close();
    _account = account;
    _count = account == null ? null : LoadCubit<int>(_repository!.draftCount);
    _dirty = true;
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (!identical(router, _router)) {
      _router?.routerDelegate.removeListener(_routeChanged);
      _router = router;
      router?.routerDelegate.addListener(_routeChanged);
    }
    _routeChanged();
  }

  void _routeChanged() {
    if (!mounted) return;
    final visible =
        (_router == null || _router!.state.uri.path == '/teacher/more') &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    final returning = visible && !_visible;
    _visible = visible;
    if (visible && (returning || _dirty)) _reload();
  }

  void _reload() {
    final count = _count;
    if (count == null) return;
    _dirty = false;
    unawaited(count.load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _dirty = true;
      if (_visible) _reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router?.routerDelegate.removeListener(_routeChanged);
    _authSubscription?.cancel();
    _subscriptionListener?.cancel();
    _changesSubscription?.cancel();
    _count?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    if (count == null) return _tile(null);
    return BlocBuilder<LoadCubit<int>, LoadState<int>>(
      key: ObjectKey(count),
      bloc: count,
      builder: (_, state) => _tile(
        state.status == LoadStatus.error ? null : state.value,
        failed: state.status == LoadStatus.error,
      ),
    );
  }

  Widget _tile(int? count, {bool failed = false}) {
    final pending = count != null && count > 0;
    final item = widget.item;
    return MoreMenuTile(
      key: ValueKey('more-menu-${item.id}'),
      item: MoreMenuItem(
        id: item.id,
        title: item.title,
        description: failed
            ? 'Jumlah draf belum dapat dimuat. Buka laporan untuk memeriksa.'
            : pending
            ? '$count laporan draf belum diterbitkan'
            : item.description,
        route: item.route,
        icon: item.icon,
        foreground: item.foreground,
        background: item.background,
      ),
      trailing: pending
          ? Semantics(
              key: const ValueKey('reports-draft-count'),
              label: '$count laporan draf belum diterbitkan',
              child: ExcludeSemantics(
                child: Badge(
                  backgroundColor: NalaraColors.danger,
                  textColor: NalaraColors.surface,
                  label: Text('$count'),
                ),
              ),
            )
          : null,
      onTap: () => widget.onOpen(
        pending || failed ? '${item.route}?status=draft' : item.route,
      ),
    );
  }
}
