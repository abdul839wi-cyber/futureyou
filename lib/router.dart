import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/login_screen.dart';
import 'screens/shell/app_shell.dart';
import 'screens/home/home_dashboard_screen.dart';
import 'screens/future/future_screen.dart';
import 'screens/today/today_screen.dart';
import 'screens/labs/lab_screen.dart';
import 'package:future_you/screens/timeline/medical_timeline_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // Main App Shell (tabs) — all tabs reuse the same placeholder widget
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeDashboardScreen(),
        ),
        GoRoute(
          path: '/future',
          builder: (context, state) => const FutureScreen(),
        ),
        GoRoute(
          path: '/today',
          builder: (context, state) => const TodayScreen(),
        ),
        GoRoute(
          path: '/timeline',
          builder: (context, state) => const MedicalTimelineScreen(),
        ),
        GoRoute(path: '/lab', builder: (context, state) => const LabScreen()),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Navigation error')),
    body: Center(
      child: Text(
        state.error?.toString() ?? 'Unknown routing error',
        textAlign: TextAlign.center,
      ),
    ),
  ),
);

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text(
          'Placeholder screen.\nWe will replace this with real UI.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
