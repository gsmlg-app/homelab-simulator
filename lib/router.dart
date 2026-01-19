import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/game_screen.dart';

/// App route destinations
class Destinations {
  Destinations._();

  static const String game = '/';
  static const String settings = '/settings';

  static List<String> get routeNames => [game, settings];
}

/// App router configuration
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: key,
    initialLocation: Destinations.game,
    routes: [
      GoRoute(
        path: Destinations.game,
        name: 'game',
        builder: (context, state) => const GameScreen(),
      ),
      // TODO: Add settings route
      // GoRoute(
      //   path: Destinations.settings,
      //   name: 'settings',
      //   builder: (context, state) => const SettingsScreen(),
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(Destinations.game),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
