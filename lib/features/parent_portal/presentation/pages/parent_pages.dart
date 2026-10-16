import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/nalara_page_header.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../shared/widgets/parent_bottom_navigation.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../dashboard/presentation/widgets/home_style.dart';

class ParentShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ParentShell({super.key, required this.shell});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HomeStyle.cream,
    body: shell,
    bottomNavigationBar: ParentBottomNavigation(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: true),
    ),
  );
}

abstract final class ParentStyle {
  static const cream = Color(0xFFF7F3EC),
      green = Color(0xFF155A49),
      ink = Color(0xFF12191A),
      muted = Color(0xFF6E7377),
      pale = Color(0xFFE4EDE2),
      warning = Color(0xFFFDECE9);
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 25,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const subtitle = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 15,
    height: 1.45,
    color: muted,
  );
  static const section = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 14,
    height: 1.45,
    color: muted,
  );
  static const strong = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ink,
  );
}

class ParentProfilePage extends StatelessWidget {
  const ParentProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final profile = getIt<AuthCubit>().state.accessProfile;
    return Scaffold(
      backgroundColor: ParentStyle.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            NalaraPageHeader(
              title: 'Profil orang tua',
              onBack: () => context.pop(),
              showDivider: true,
            ),
            NalaraSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?.name ?? '-', style: ParentStyle.title),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Nomor HP',
                    value: profile?.phone?.isNotEmpty == true
                        ? profile!.phone!
                        : '-',
                  ),
                  _InfoRow(
                    label: 'Keluarga',
                    value: profile?.familyName?.isNotEmpty == true
                        ? profile!.familyName!
                        : '-',
                  ),
                  _InfoRow(
                    label: 'Anak terhubung',
                    value: '${profile?.children.length ?? 0}',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Data ini dikelola Guru pada menu keluarga.',
                    style: ParentStyle.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 115, child: Text(label, style: ParentStyle.body)),
        Expanded(child: Text(value, style: ParentStyle.strong)),
      ],
    ),
  );
}
