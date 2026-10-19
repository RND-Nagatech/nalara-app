import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/parent_bottom_navigation.dart';
import '../../../profile/presentation/pages/profile_page.dart';
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

class ParentProfilePage extends StatelessWidget {
  const ParentProfilePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const ProfilePage(parent: true, routePrefix: '/parent');
}
