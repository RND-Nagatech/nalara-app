import 'package:flutter/material.dart';
import 'nalara_bottom_navigation.dart';

const teacherNavigationLocations = [
  '/teacher/home',
  '/teacher/students',
  '/teacher/schedule',
  '/teacher/targets',
  '/teacher/more',
];

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
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Siswa',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Jadwal',
      ),
      NavigationDestination(
        icon: Icon(Icons.flag_outlined),
        selectedIcon: Icon(Icons.flag),
        label: 'Target',
      ),
      NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view),
        label: 'Lainnya',
      ),
    ],
  );
}
