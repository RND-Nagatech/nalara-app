import 'package:flutter/material.dart';
import 'nalara_bottom_navigation.dart';

const studentNavigationLocations = [
  '/student/home',
  '/student/schedule',
  '/student/targets',
  '/student/reports',
  '/student/more',
];

class StudentBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const StudentBottomNavigation({
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
        icon: Icon(Icons.description_outlined),
        selectedIcon: Icon(Icons.description),
        label: 'Laporan',
      ),
      NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view),
        label: 'Lainnya',
      ),
    ],
  );
}
