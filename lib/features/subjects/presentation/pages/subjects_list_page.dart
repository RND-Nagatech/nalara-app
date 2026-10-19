import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_empty_state.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../shared/widgets/nalara_error_notice.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/teaching_catalog_refresh.dart';
import '../../../../shared/widgets/nalara_load_more.dart';
import '../../../../utils/injector.dart';
import '../../domain/repositories/subjects_repository.dart';
import '../bloc/subjects_cubit.dart';
import '../widgets/subject_form_style.dart';
import '../widgets/subject_list_card.dart';
import '../widgets/subjects_header.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage>
    with TeachingCatalogRefresh<SubjectsPage> {
  late final SubjectsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SubjectsCubit(getIt<SubjectsRepository>())..refresh();
  }

  @override
  void onTeachingCatalogChanged() => _cubit.reload();

  Future<void> _open(String route, {bool adding = false}) async {
    await context.push(route);
    if (!mounted) return;
    await _cubit.refresh();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: SubjectFormStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: SubjectFormStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: BlocBuilder<SubjectsCubit, SubjectsState>(
                bloc: _cubit,
                builder: (context, state) => RefreshIndicator(
                  color: SubjectFormStyle.green,
                  onRefresh: _cubit.refresh,
                  child: NalaraPageLayout(
                    header: SubjectsHeader(
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/teacher/more');
                        }
                      },
                      onRefresh: state.loading ? null : _cubit.refresh,
                    ),
                    body: CustomScrollView(
                      key: const PageStorageKey('subjects-scroll'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _addButton()),
                        if (state.loading && state.result != null)
                          const SliverPadding(
                            padding: EdgeInsets.fromLTRB(22, 18, 22, 0),
                            sliver: SliverToBoxAdapter(
                              child: LinearProgressIndicator(),
                            ),
                          ),
                        if (state.error != null)
                          SliverToBoxAdapter(child: _error(state.error!)),
                        if (state.result == null && state.loading)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _empty(),
                          )
                        else if (state.result != null) ...[
                          SliverToBoxAdapter(child: _sectionTitle(state)),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                            sliver: SliverList.builder(
                              itemCount: state.result!.items.length,
                              itemBuilder: (context, index) {
                                final subject = state.result!.items[index];
                                return SubjectListCard(
                                  key: ValueKey(subject.id),
                                  subject: subject,
                                  onEdit: () => _open(
                                    '/teacher/subjects/${Uri.encodeComponent(subject.id)}/edit',
                                  ),
                                );
                              },
                            ),
                          ),
                          if (state.result!.items.isNotEmpty)
                            const SliverPadding(
                              padding: EdgeInsets.fromLTRB(26, 6, 26, 20),
                              sliver: SliverToBoxAdapter(
                                child: Text(
                                  'Perubahan nama ikut diterapkan pada jadwal, target, dan laporan.',
                                  style: TextStyle(
                                    fontFamily: 'NalaraInter',
                                    fontSize: 11.5,
                                    height: 1.5,
                                    color: SubjectFormStyle.muted,
                                  ),
                                ),
                              ),
                            ),
                          if (state.result!.total > state.result!.limit)
                            SliverToBoxAdapter(child: _pagination(state)),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _addButton() => Padding(
    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
    child: FilledButton(
      key: const ValueKey('subjects-add'),
      onPressed: () => _open('/teacher/subjects/new', adding: true),
      child: const Text('Tambah bidang belajar'),
    ),
  );

  Widget _sectionTitle(SubjectsState state) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        const Text(
          'Bidang yang diajarkan',
          style: TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: SubjectFormStyle.ink,
          ),
        ),
        Text(
          '${state.result!.total} bidang',
          style: const TextStyle(
            fontFamily: 'NalaraInter',
            color: SubjectFormStyle.muted,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  Widget _empty() => const NalaraEmptyState(
    imagePath: 'assets/Empty/empty siswa.png',
    title: 'Belum ada bidang belajar',
    message:
        'Tambahkan bidang yang Anda ajarkan, seperti Matematika, Piano, atau Renang.',
  );

  Widget _error(String message) => ErrorNotice(
    message,
    retry: _cubit.reload,
    compact: _cubit.state.result?.items.isNotEmpty ?? false,
  );

  Widget _pagination(SubjectsState state) {
    final result = state.result!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      child: NalaraLoadMoreButton(
        buttonKey: const ValueKey('subjects-load-more'),
        hasMore: result.hasNext,
        loading: state.loading,
        onPressed: _cubit.loadMore,
      ),
    );
  }
}
