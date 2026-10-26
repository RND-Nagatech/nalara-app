import 'package:flutter/material.dart';
import '../../features/teaching_guide/presentation/teaching_tutorial_scope.dart';
import '../../features/profile/presentation/widgets/profile_completion_badge.dart';
import 'nalara_bottom_navigation.dart';

const teacherNavigationLocations = [
  '/teacher/home',
  '/teacher/students',
  '/teacher/schedule',
  '/teacher/targets',
  '/teacher/more',
];

bool isTeacherShellLocation(String route) =>
    teacherNavigationLocations.contains(route);

/// Shared visual navigation; callers retain ownership of routing/branch state.
class TeacherBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const TeacherBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  @override
  Widget build(BuildContext context) => NalaraBottomNavigation(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Beranda',
      ),
      NavigationDestination(
        icon: TutorialTarget(
          id: 'menu-student',
          child: Icon(Icons.people_outline),
        ),
        selectedIcon: TutorialTarget(
          id: 'menu-student',
          child: Icon(Icons.people),
        ),
        label: 'Siswa',
      ),
      NavigationDestination(
        icon: TutorialTarget(
          id: 'menu-schedule',
          child: Icon(Icons.calendar_month_outlined),
        ),
        selectedIcon: TutorialTarget(
          id: 'menu-schedule',
          child: Icon(Icons.calendar_month),
        ),
        label: 'Jadwal',
      ),
      NavigationDestination(
        icon: TutorialTarget(
          id: 'menu-target',
          child: Icon(Icons.flag_outlined),
        ),
        selectedIcon: TutorialTarget(
          id: 'menu-target',
          child: Icon(Icons.flag),
        ),
        label: 'Target',
      ),
      NavigationDestination(
        icon: TutorialTarget(
          id: 'menu-subject',
          child: ProfileCompletionBadge(
            includeGuide: true,
            child: Icon(Icons.grid_view_outlined),
          ),
        ),
        selectedIcon: TutorialTarget(
          id: 'menu-subject',
          child: ProfileCompletionBadge(
            includeGuide: true,
            child: Icon(Icons.grid_view),
          ),
        ),
        label: 'Lainnya',
      ),
    ],
  );
}
