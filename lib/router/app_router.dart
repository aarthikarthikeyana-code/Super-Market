import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../store/admin_app.dart';
import '../store/customer_app.dart';
import '../store/delivery_app.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/delivery',
      builder: (_, _) => const DeliveryConsoleScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const StorefrontScreen();
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (BuildContext context, GoRouterState state) {
        return const AdminConsoleScreen();
      },
    ),
    GoRoute(
      path: '/employee',
      builder: (BuildContext context, GoRouterState state) {
        return EmployeeConsoleScreen(
          onSwitchToAdmin: () => context.go('/admin'),
        );
      },
    ),
    GoRoute(
      path: '/customer',
      builder: (BuildContext context, GoRouterState state) {
        return const StorefrontScreen();
      },
    ),
    GoRoute(
      path: '/customer-app',
      builder: (BuildContext context, GoRouterState state) {
        return const StorefrontScreen();
      },
    ),
  ],
);
