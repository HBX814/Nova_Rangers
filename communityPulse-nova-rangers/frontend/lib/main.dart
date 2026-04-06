import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:firebase_core/firebase_core.dart';

import 'screens/home_screen.dart';
import 'screens/needs_screen.dart';
import 'screens/volunteers_screen.dart';
import 'screens/submit_report_screen.dart';
import 'screens/analytics_screen.dart';

/// CommunityPulse — Volunteer Coordination Platform
///
/// Entry point for the Flutter application (mobile + web).
/// Initialises Firebase and sets up GoRouter navigation.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialise Firebase when firebase_options.dart is generated
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(
    const ProviderScope(
      child: CommunityPulseApp(),
    ),
  );
}

/// App-wide GoRouter configuration
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/needs',
          name: 'needs',
          builder: (context, state) => const NeedsScreen(),
        ),
        GoRoute(
          path: '/volunteers',
          name: 'volunteers',
          builder: (context, state) => const VolunteersScreen(),
        ),
        GoRoute(
          path: '/submit',
          name: 'submit',
          builder: (context, state) => const SubmitReportScreen(),
        ),
        GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
      ],
    ),
  ],
);

class CommunityPulseApp extends StatelessWidget {
  const CommunityPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CommunityPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32), // Green — social impact
        brightness: Brightness.light,
        fontFamily: 'NotoSans',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
        brightness: Brightness.dark,
        fontFamily: 'NotoSans',
      ),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

/// Shell widget providing the bottom navigation bar
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/needs')) return 1;
    if (location.startsWith('/volunteers')) return 2;
    if (location.startsWith('/submit')) return 3;
    if (location.startsWith('/analytics')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.goNamed('home');
              break;
            case 1:
              context.goNamed('needs');
              break;
            case 2:
              context.goNamed('volunteers');
              break;
            case 3:
              context.goNamed('submit');
              break;
            case 4:
              context.goNamed('analytics');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Needs',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Volunteers',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
