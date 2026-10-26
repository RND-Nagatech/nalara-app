import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../shared/widgets/nalara_error_notice.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_load_more.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../../shared/domain/app_timezones.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../bloc/notifications_cubit.dart';
import '../widgets/notification_card.dart';
import '../widgets/notifications_empty_state.dart';
import '../widgets/notifications_style.dart';

class NotificationsPage extends StatefulWidget {
  final NotificationsRepository? repository;
  final String routePrefix;
  const NotificationsPage({
    super.key,
    this.repository,
    this.routePrefix = '/teacher',
  });
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = NotificationsCubit(
      widget.repository ?? getIt<NotificationsRepository>(),
    )..reload();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  bool get _visible {
    final router = GoRouter.maybeOf(context);
    return (ModalRoute.of(context)?.isCurrent ?? true) &&
        (router == null ||
            router.state.uri.path == '${widget.routePrefix}/notifications');
  }

  Future<void> _open(TeacherNotification notification) async {
    if (!_visible) return;
    final ok = await _cubit.markRead(notification.id);
    if (!ok || !mounted) return;
    if (_visible && notification.route.startsWith('${widget.routePrefix}/')) {
      await context.push(notification.route);
    }
    if (mounted) await _cubit.reload();
  }

  Future<void> _markRead(TeacherNotification notification) async {
    final ok = await _cubit.markRead(notification.id);
    if (ok && mounted) await _cubit.reload();
  }

  Future<void> _markAllRead() async {
    final ok = await _cubit.markAllRead();
    if (ok && mounted) await _cubit.reload();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: NotificationsStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: NotificationsStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                bloc: _cubit,
                builder: (context, state) => Column(
                  children: [
                    NalaraHeader(child: _header(context, state)),
                    Expanded(
                      child: RefreshIndicator(
                        color: NotificationsStyle.green,
                        onRefresh: _cubit.refresh,
                        child: _body(state),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header(
    BuildContext context,
    NotificationsState state,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 360;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('notifications-back'),
              tooltip: 'Kembali',
              style: NotificationsStyle.roundButton,
              onPressed: () =>
                  finishForm(context, '${widget.routePrefix}/more'),
              icon: const Icon(Icons.arrow_back_rounded, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Notifikasi',
                style: TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: NotificationsStyle.ink,
                ),
              ),
            ),
            if (state.result?.items.any((item) => !item.read) ?? false)
              compact
                  ? IconButton(
                      key: const ValueKey('notifications-read-all'),
                      tooltip: 'Tandai semua dibaca',
                      onPressed: state.canInteract ? _markAllRead : null,
                      icon: state.markingAll
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.done_all_rounded),
                    )
                  : TextButton(
                      key: const ValueKey('notifications-read-all'),
                      onPressed: state.canInteract ? _markAllRead : null,
                      child: state.markingAll
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Tandai semua dibaca'),
                    ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('notifications-refresh'),
              tooltip: 'Muat ulang notifikasi',
              style: NotificationsStyle.roundButton,
              onPressed: state.loading || state.busyId != null
                  ? null
                  : _cubit.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 23),
            ),
          ],
        ),
      );
    },
  );

  Widget _body(NotificationsState state) => CustomScrollView(
    key: const PageStorageKey('notifications-scroll'),
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(22, 16, 22, 20),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Informasi terbaru seputar aktivitas belajar Anda.',
            style: NotificationsStyle.body,
          ),
        ),
      ),
      if (state.loading && state.result != null)
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 14),
          sliver: SliverToBoxAdapter(child: LinearProgressIndicator()),
        ),
      if (state.error != null) SliverToBoxAdapter(child: _error(state.error!)),
      if (state.result == null && state.loading)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        )
      else if (state.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: NotificationsEmptyState()),
        )
      else if (state.result != null && state.result!.total > 0) ...[
        SliverToBoxAdapter(child: _summary(state)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          sliver: SliverList.builder(
            itemCount: state.result!.items.length,
            itemBuilder: (context, index) {
              final notification = state.result!.items[index];
              return NotificationCard(
                key: ValueKey('notification-${notification.id}'),
                notification: notification,
                timezone:
                    widget.routePrefix == '/teacher' &&
                        getIt.isRegistered<AuthCubit>()
                    ? getIt<AuthCubit>().state.teacher?.timezone ??
                          AppTimezones.jakarta
                    : AppTimezones.jakarta,
                busy: state.busyId == notification.id,
                error: state.actionErrorId == notification.id
                    ? state.actionError
                    : null,
                onOpen: state.canInteract ? () => _open(notification) : null,
                onMarkRead: state.canInteract && !notification.read
                    ? () => _markRead(notification)
                    : null,
              );
            },
          ),
        ),
        if (state.result!.hasNext)
          SliverToBoxAdapter(child: _pagination(state)),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ],
  );

  Widget _summary(NotificationsState state) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        Text(
          'Kotak masuk',
          style: NotificationsStyle.body.copyWith(
            color: NotificationsStyle.ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${state.result!.total} notifikasi',
          style: NotificationsStyle.body.copyWith(fontSize: 12),
        ),
      ],
    ),
  );

  Widget _error(String error) => ErrorNotice(
    error,
    retry: _cubit.reload,
    retryKey: const ValueKey('notifications-retry'),
    compact: _cubit.state.result?.items.isNotEmpty ?? false,
  );

  Widget _pagination(NotificationsState state) {
    final result = state.result!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
      child: NalaraLoadMoreButton(
        buttonKey: const ValueKey('notifications-load-more'),
        hasMore: result.hasNext,
        loading: state.loading,
        onPressed: _cubit.loadMore,
      ),
    );
  }
}
