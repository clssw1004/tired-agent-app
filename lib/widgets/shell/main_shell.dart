import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.primary, width: 0.5)),
        ),
        child: BottomNavigationBar(
          backgroundColor: c.background,
          selectedItemColor: c.primary,
          unselectedItemColor: c.textSecondary,
          type: BottomNavigationBarType.fixed,
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            // Go to the branch, preserving stack if already on it
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dns_outlined),
              activeIcon: Icon(Icons.dns),
              label: AppStrings.of.navManagers,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.push_pin_outlined),
              activeIcon: Icon(Icons.push_pin),
              label: AppStrings.of.navSessions,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: AppStrings.of.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
