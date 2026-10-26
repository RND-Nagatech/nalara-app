import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/state/teaching_catalog_refresh.dart';
import '../../../shared/widgets/nalara_avatar.dart';
import '../../../shared/widgets/nalara_header.dart';
import '../../../shared/widgets/nalara_load_more.dart';
import '../../../shared/widgets/nalara_page_header.dart';
import '../../../shared/widgets/nalara_surface_card.dart';
import '../../../shared/widgets/page_widgets.dart';
import '../../../utils/color.dart';
import '../../../utils/injector.dart';
import '../domain/student_group.dart';
import '../domain/student_groups_repository.dart';
import 'student_groups_cubit.dart';

class StudentGroupsPage extends StatefulWidget {
  const StudentGroupsPage({super.key});
  @override
  State<StudentGroupsPage> createState() => _StudentGroupsPageState();
}

class _StudentGroupsPageState extends State<StudentGroupsPage>
    with TeachingCatalogRefresh<StudentGroupsPage> {
  late final _cubit = StudentGroupsCubit(getIt<StudentGroupsRepository>())
    ..refresh();
  final _search = TextEditingController();
  @override
  void onTeachingCatalogChanged() => _cubit.refresh();
  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) await _cubit.refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<StudentGroupsCubit, StudentGroupsState>(
    bloc: _cubit,
    builder: (context, state) => Scaffold(
      backgroundColor: NalaraColors.cream,
      floatingActionButton: state.result?.items.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () => _open('/teacher/student-groups/new'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah grup'),
            )
          : null,
      body: NalaraPageLayout(
        header: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NalaraPageHeader(
              title: 'Grup siswa',
              subtitle: 'Kelompokkan siswa untuk jadwal rutin',
              actions: [
                IconButton(
                  onPressed: state.loading ? null : _cubit.refresh,
                  tooltip: 'Muat ulang grup',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                onChanged: _cubit.search,
                decoration: const InputDecoration(
                  hintText: 'Cari grup siswa',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.loading)
                  const SliverToBoxAdapter(child: LinearProgressIndicator()),
                if (state.error != null)
                  SliverToBoxAdapter(
                    child: ErrorNotice(
                      state.error!,
                      retry: _cubit.retry,
                      compact: state.result?.items.isNotEmpty == true,
                    ),
                  ),
                if (state.result?.items.isEmpty == true)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyNotice(
                      _search.text.trim().isEmpty
                          ? 'Buat grup agar siswa untuk jadwal rutin bisa dipilih sekaligus.'
                          : 'Belum ada grup yang sesuai pencarian.',
                      imagePath: 'assets/Empty/empty siswa.png',
                      action: _search.text.trim().isEmpty
                          ? FilledButton(
                              onPressed: () =>
                                  _open('/teacher/student-groups/new'),
                              child: const Text('Buat grup siswa'),
                            )
                          : null,
                    ),
                  ),
                if (state.result?.items.isNotEmpty == true) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverList.builder(
                      itemCount: state.result!.items.length,
                      itemBuilder: (context, index) {
                        final group = state.result!.items[index];
                        return _GroupCard(
                          key: ValueKey(group.id),
                          group: group,
                          onEdit: () => _open(
                            '/teacher/student-groups/${Uri.encodeComponent(group.id)}/edit',
                          ),
                          onSchedule: () => _open(
                            '/teacher/schedule/new?groupId=${Uri.encodeComponent(group.id)}',
                          ),
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverToBoxAdapter(
                      child: NalaraLoadMoreButton(
                        hasMore: state.result!.hasNext,
                        loading: state.loading,
                        onPressed: _cubit.loadMore,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _GroupCard extends StatelessWidget {
  final StudentGroup group;
  final VoidCallback onEdit, onSchedule;
  const _GroupCard({
    super.key,
    required this.group,
    required this.onEdit,
    required this.onSchedule,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: NalaraSurfaceCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: NalaraColors.green,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${group.studentIds.length} siswa',
            style: const TextStyle(color: NalaraColors.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final student in group.students.take(4))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NalaraAvatar(
                      name: student.name,
                      avatarId: student.avatarId,
                      size: 28,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        student.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (group.students.length > 4)
                Text('+${group.students.length - 4} lainnya'),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onSchedule,
              child: const Text('Buat jadwal untuk grup'),
            ),
          ),
        ],
      ),
    ),
  );
}
