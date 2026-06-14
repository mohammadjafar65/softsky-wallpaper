import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard_screen.dart';
import '../screens/wallpapers_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/users_screen.dart';
import '../screens/packs_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../services/auth_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  redirect: (context, state) {
    final isLoggedIn = AuthService.isLoggedIn;
    if (!isLoggedIn && state.matchedLocation != '/login') {
      return '/login';
    }
    if (isLoggedIn && state.matchedLocation == '/login') {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, state) => const DashboardScreen()),
        GoRoute(path: '/wallpapers', builder: (_, state) => const WallpapersScreen()),
        GoRoute(path: '/categories', builder: (_, state) => const CategoriesScreen()),
        GoRoute(path: '/users', builder: (_, state) => const UsersScreen()),
        GoRoute(path: '/packs', builder: (_, state) => const PacksScreen()),
        GoRoute(path: '/notifications', builder: (_, state) => const NotificationsScreen()),
        GoRoute(path: '/subscriptions', builder: (_, state) => const SubscriptionsScreen()),
      ],
    ),
  ],
);
