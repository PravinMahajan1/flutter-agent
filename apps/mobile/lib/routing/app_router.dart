import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_store.dart';
import '../screens/auth/login_screen.dart';
import '../screens/shell/student_shell.dart';
import '../screens/shell/teacher_shell.dart';
import '../screens/shell/admin_shell.dart';

GoRouter buildRouter(AuthStore auth) {
  return GoRouter(
    initialLocation: auth.isAuthenticated ? '/home' : '/login',
    refreshListenable: auth,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/home',
        redirect: (context, state) {
          final role = context.read<AuthStore>().role;
          if (role == 'STUDENT') return '/student';
          if (role == 'TEACHER') return '/teacher';
          if (role == 'ADMIN') return '/admin';
          return '/login';
        },
      ),
      ShellRoute(
        builder: (context, state, child) => const StudentShell(),
        routes: [
          GoRoute(path: '/student', builder: (context, state) => const SizedBox()),
          GoRoute(path: '/student/dashboard', builder: (context, state) => const SizedBox()),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => const TeacherShell(),
        routes: [
          GoRoute(path: '/teacher', builder: (context, state) => const SizedBox()),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => const AdminShell(),
        routes: [
          GoRoute(path: '/admin', builder: (context, state) => const SizedBox()),
        ],
      ),
    ],
    redirect: (context, state) {
      final authStore = context.read<AuthStore>();
      final loggingIn = state.matchedLocation == '/login';
      if (!authStore.isAuthenticated) return loggingIn ? null : '/login';
      if (loggingIn && authStore.isAuthenticated) return '/home';
      return null;
    },
  );
}

