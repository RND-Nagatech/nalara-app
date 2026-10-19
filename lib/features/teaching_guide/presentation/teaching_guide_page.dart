import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/state/teaching_catalog_refresh.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../../shared/widgets/nalara_page_header.dart';
import '../../../utils/injector.dart';
import 'teaching_guide_card.dart';
import 'teaching_guide_cubit.dart';

class TeachingGuidePage extends StatefulWidget {
  const TeachingGuidePage({super.key});
  @override
  State<TeachingGuidePage> createState() => _TeachingGuidePageState();
}

class _TeachingGuidePageState extends State<TeachingGuidePage>
    with WidgetsBindingObserver, TeachingCatalogRefresh<TeachingGuidePage> {
  late final TeachingGuideCubit _cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = getIt<TeachingGuideCubit>()..load();
  }

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
    if (_cubit.state.busy || !_visible) return;
    await context.push(route);
    if (mounted && _visible) await _cubit.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NalaraPageScaffold(
    title: 'Panduan mulai mengajar',
    onBack: () => finishForm(context, '/teacher/home'),
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
            children: [TeachingGuideCard(cubit: _cubit, onOpen: _open)],
          ),
        ),
      ),
    ),
  );
}
