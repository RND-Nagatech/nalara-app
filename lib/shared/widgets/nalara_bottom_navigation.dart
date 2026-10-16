import 'package:flutter/material.dart';

/// The single visual bottom-navigation implementation used by every role.
/// Each role only supplies its own destinations and routing callback.
class NalaraBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const NalaraBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      boxShadow: [
        BoxShadow(
          color: Color(0x08786951),
          blurRadius: 16,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 78,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: const Color(0xFFE4EDE2),
          indicatorShape: const StadiumBorder(),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 25,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF155A49)
                  : const Color(0xFF666C6D),
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF155A49)
                  : const Color(0xFF666C6D),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      ),
    ),
  );
}
