import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Shell
import '../../features/core_ui/presentation/screens/main_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShell(),
    ),
  ],
);
