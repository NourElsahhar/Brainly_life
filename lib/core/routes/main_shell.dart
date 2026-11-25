// MainShell = the screen frame with the bottom navigation bar.
// It shows the current tab and keeps each tab's own state.
// The tabs themselves are listed in app_router.dart (appTabs).
// The look of the bar will be matched to the design later.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppTab {
  const AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.routes,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final List<RouteBase> routes;
}

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    required this.tabs,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the current tab again goes back to its first screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
