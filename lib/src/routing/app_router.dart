import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/editor/presentation/editor_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/export/presentation/export_screen.dart';
import '../features/auth/providers/auth_provider.dart';

/// Route names
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String editor = '/editor/:id';
  static const String newEditor = '/editor/new';
  static const String settings = '/settings';
  static const String export = '/export/:id';
  static const String paywall = '/paywall';

  static String editorPath(String id) => '/editor/$id';
  static String exportPath(String id) => '/export/$id';
}

/// App router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isRegistering = state.matchedLocation == AppRoutes.register;

      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return AppRoutes.login;
      }

      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/editor/new',
        name: 'newEditor',
        builder: (context, state) => const EditorScreen(mindMapId: null),
      ),
      GoRoute(
        path: '/editor/:id',
        name: 'editor',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return EditorScreen(mindMapId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/export/:id',
        name: 'export',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ExportScreen(mindMapId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
