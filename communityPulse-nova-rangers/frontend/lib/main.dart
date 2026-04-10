import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';

import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/need_detail_screen.dart';
import 'screens/needs_list_screen.dart';
import 'screens/submission_screen.dart';
import 'screens/volunteer_home_screen.dart';
import 'screens/volunteer_profile_screen.dart';
import 'screens/volunteer_task_feed_screen.dart';
import 'theme.dart';

/// CommunityPulse — Volunteer Coordination Platform
///
/// Entry point: initialises Firebase then mounts the Riverpod [ProviderScope]
/// and the [CommunityPulseApp] widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const ProviderScope(
      child: CommunityPulseApp(),
    ),
  );
}

// ── Router ──────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/needs',
      name: 'needs',
      builder: (context, state) => const NeedsListScreen(),
    ),
    GoRoute(
      path: '/needs/:needId',
      name: 'needDetail',
      builder: (context, state) {
        final needId = state.pathParameters['needId']!;
        return NeedDetailScreen(needId: needId);
      },
    ),
    GoRoute(
      path: '/submit',
      name: 'submit',
      builder: (context, state) => const SubmissionScreen(),
    ),
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/volunteer',
      name: 'volunteerHome',
      builder: (context, state) => const VolunteerHomeScreen(),
    ),
    GoRoute(
      path: '/volunteer/tasks',
      name: 'volunteerTasks',
      builder: (context, state) => const VolunteerTaskFeedScreen(),
    ),
    GoRoute(
      path: '/volunteer/profile',
      name: 'volunteerProfile',
      builder: (context, state) => const VolunteerProfileScreen(),
    ),
  ],
);

// ── Root app widget ──────────────────────────────────────────────────────────

class CommunityPulseApp extends StatelessWidget {
  const CommunityPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CommunityPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
