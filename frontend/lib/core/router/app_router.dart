import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/signup_verify_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/auth/login',
    redirect: (context, state) async {
      final isAuth = await ref.read(authRepositoryProvider).isAuthenticated();
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/signup/verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SignupVerifyScreen(
            phoneNumber: extra?['phone'] as String? ?? '',
            email: extra?['email'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}