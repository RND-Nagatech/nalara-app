import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/state/teaching_catalog_refresh.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../../shared/widgets/nalara_page_header.dart';
import '../../../shared/widgets/teacher_bottom_navigation.dart';
import '../../../utils/injector.dart';
import 'teaching_guide_card.dart';
import 'teaching_guide_cubit.dart';
import 'teaching_guide_extras.dart';
import 'teaching_tutorial_scope.dart';
import '../domain/teaching_guide.dart';

class TeachingGuidePage extends StatefulWidget {
  const TeachingGuidePage({super.key});
  @override
  State<TeachingGuidePage> createState() => _TeachingGuidePageState();
}

class _TeachingGuidePageState extends State<TeachingGuidePage>
    with WidgetsBindingObserver, TeachingCatalogRefresh<TeachingGuidePage> {
  TeachingGuideCubit? _boundCubit;
  TeachingGuideCubit get _cubit => _boundCubit!;
  bool _ownsCubit = false;
  bool _navigationInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_boundCubit != null) return;
    _boundCubit = TeachingTutorialScope.maybeOf(context)?.guide;
    _ownsCubit = _boundCubit == null;
    _boundCubit ??= getIt<TeachingGuideCubit>();
    if (!_cubit.state.busy) _cubit.load();
  }

  void _start(TeachingGuideStep step) =>
      TeachingTutorialScope.maybeOf(context)?.start(step);

  @override
  void onTeachingCatalogChanged() => _cubit.load();

  bool get _visible =>
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      (GoRouter.maybeOf(context)?.state.uri.path == '/teacher/getting-started');

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _visible) _cubit.load();
  }

  Future<void> _open(String route) async {
    if (_cubit.state.busy || !_visible || _navigationInFlight) return;
    _navigationInFlight = true;
    try {
      if (isTeacherShellLocation(route)) {
        context.go(route);
      } else {
        await context.push(route);
        if (mounted && _visible) await _cubit.load();
      }
    } finally {
      _navigationInFlight = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsCubit) _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NalaraPageScaffold(
    title: 'Panduan mulai mengajar',
    onBack: () => finishForm(context, '/teacher/more'),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: RefreshIndicator(
          onRefresh: _cubit.load,
          child: ListView(
            key: const PageStorageKey('teaching-guide-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              TeachingGuideCard(cubit: _cubit, onOpen: _open, onStart: _start),
              BlocBuilder<TeachingGuideCubit, TeachingGuideState>(
                bloc: _cubit,
                builder: (_, state) => state.value == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: TeachingGuideExtras(
                          onOpen: _open,
                          enabled: !state.busy,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
