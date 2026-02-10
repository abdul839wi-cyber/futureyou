import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _indexFromLocation(String location) {
    // Normalize: if you ever add nested routes later, this still works.
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/future')) return 1;
    if (location.startsWith('/today')) return 2;
    if (location.startsWith('/timeline')) return 3;
    if (location.startsWith('/lab')) return 4;
    return 0;
  }

  void _goToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        return;
      case 1:
        context.go('/future');
        return;
      case 2:
        context.go('/today');
        return;
      case 3:
        context.go('/timeline');
        return;
      case 4:
        context.go('/lab');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // GoRouter's current location
    final String location = GoRouterState.of(context).uri.toString();
    final int currentIndex = _indexFromLocation(location);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(currentIndex)),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // AuthGate will send user to Landing automatically
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _goToIndex(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Future',
          ),
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'Lab',
          ),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Future';
      case 2:
        return 'Today';
      case 3:
        return 'Timeline';
      case 4:
        return 'Lab';
      default:
        return 'FutureYou';
    }
  }
}
