import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Placeholder for screens
import '../../features/project_analysis/presentation/screens/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
