import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/home_screen.dart';
import '../pet/pet_screen.dart';
import '../profile/profile_screen.dart';
import '../projects/projects_screen.dart';
import 'shell_controller.dart';

/// Bottom navigation with labelled icons and a filled active state, so Home
/// clearly reads as a button (usability feedback #5).
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShellController>();
    final tab = controller.value;
    return PopScope(
      canPop: tab == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.go(AppTab.home);
      },
      child: Scaffold(
        body: IndexedStack(
          index: tab.index,
          children: const [HomeScreen(), ProjectsScreen(), PetScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (i) => controller.go(AppTab.values[i]),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism_rounded),
              label: 'Donate',
            ),
            NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets_rounded), label: 'Pet'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
