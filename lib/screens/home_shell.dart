import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'activity_log_screen.dart';
import 'coach_screen.dart';
import 'dashboard_screen.dart';
import 'groups_screen.dart';
import 'path_onboarding_screen.dart';
import 'stats_screen.dart';
import '../services/habit_provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Use IndexedStack so each tab keeps its scroll position.
  final _pages = const [
    DashboardScreen(),
    CoachScreen(),
    ActivityLogScreen(),
    GroupsScreen(),
    StatsScreen(),
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_alt_outlined),
            selectedIcon: Icon(Icons.psychology_alt),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Report',
          ),
        ],
      ),
    );
  }
}
