import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'coach_screen.dart';
import 'groups_screen.dart';
import 'path_onboarding_screen.dart';
import 'today_screen.dart';
import 'you_screen.dart';
import '../services/habit_provider.dart';

/// Four tabs, one job each:
///   Today     — do the day (ring + 1-tap loops + session)
///   Coach     — check in, get guided
///   Community — groups & social sport
///   You       — progress, body, profile, settings
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // IndexedStack keeps each tab's scroll position.
  final _pages = const [
    TodayScreen(),
    CoachScreen(),
    GroupsScreen(),
    YouScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    if (!provider.hasSelectedPath) {
      return const PathOnboardingScreen();
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_alt_outlined),
            selectedIcon: Icon(Icons.psychology_alt),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
