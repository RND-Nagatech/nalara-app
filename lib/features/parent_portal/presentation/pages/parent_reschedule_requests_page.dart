import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/nalara_page_header.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../../access/domain/entities/access_profile.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../reschedule_requests/domain/entities/reschedule_request.dart';
import '../../../reschedule_requests/presentation/bloc/reschedule_requests_cubit.dart';
import '../../../reschedule_requests/presentation/pages/reschedule_requests_page.dart';
import '../../domain/repositories/parent_portal_repository.dart';

/// Parent history and proposal responses at /parent/reschedule-requests.
class ParentRescheduleRequestsPage extends StatefulWidget {
  final String? timezone;

  const ParentRescheduleRequestsPage({super.key, this.timezone});

  @override
  State<ParentRescheduleRequestsPage> createState() =>
      _ParentRescheduleRequestsPageState();
}

class _ParentRescheduleRequestsPageState
    extends State<ParentRescheduleRequestsPage> {
  late final ParentPortalRepository _repository;
  late final RescheduleRequestsLoader _loadRequests;
  late LoadCubit<String> _timezone;

  @override
  void initState() {
    super.initState();
    _repository = getIt<ParentPortalRepository>();
    // No status filter: history includes every status returned by the server.
    _loadRequests = (page) => _repository.rescheduleRequests(page: page);
    _bindTimezone();
  }

  void _bindTimezone() {
    final timezone = widget.timezone;
    _timezone = LoadCubit<String>(
      () async => timezone ?? (await _repository.dashboard()).timezone,
    )..load();
  }

  @override
  void didUpdateWidget(covariant ParentRescheduleRequestsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timezone != widget.timezone) {
      _timezone.close();
      _bindTimezone();
    }
  }

  @override
  void dispose() {
    _timezone.close();
    super.dispose();
  }

  Future<void> _act(RescheduleRequest request, String action) =>
      switch (action) {
        'cancel' => _repository.cancelRescheduleRequest(request.id),
        _ => _repository.respondRescheduleRequest(request.id, action),
      };

  Widget _page(String timezone, AccessProfile? profile) =>
      RescheduleRequestsPage(
        parent: true,
        timezone: timezone,
        loadRequests: _loadRequests,
        onAction: _act,
        studentNames: {
          for (final child in profile?.children ?? <LinkedChild>[])
            child.id: child.name,
        },
        studentGrades: {
          for (final child in profile?.children ?? <LinkedChild>[])
            child.id: child.grade,
        },
      );

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LoadCubit<String>, LoadState<String>>(
        bloc: _timezone,
        builder: (context, state) {
          if (state.value != null) {
            if (getIt.isRegistered<AuthCubit>()) {
              return BlocBuilder<AuthCubit, AuthState>(
                bloc: getIt<AuthCubit>(),
                builder: (context, auth) =>
                    _page(state.value!, auth.accessProfile),
              );
            }
            return _page(state.value!, null);
          }
          return NalaraPageScaffold(
            title: 'Permintaan jadwal',
            subtitle: 'Riwayat perubahan jadwal anak',
            onBack: () => finishForm(context, '/parent/schedule'),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: state.status == LoadStatus.loading
                    ? null
                    : _timezone.load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            body: state.status == LoadStatus.error
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ErrorNotice(state.error!, retry: _timezone.load),
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        },
      );
}
