import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nummakadai/presentation/numma_admin_flow_shell.dart';
import '../nummakadai_customer/presentation/customer_flow_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const NummaAdminFlowShell();
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (BuildContext context, GoRouterState state) {
        return const NummaAdminFlowShell();
      },
    ),
    GoRoute(
      path: '/customer',
      builder: (BuildContext context, GoRouterState state) {
        return const NummaCustomerFlowShell();
      },
    ),
    GoRoute(
      path: '/customer-app',
      builder: (BuildContext context, GoRouterState state) {
        return const NummaCustomerFlowShell();
      },
    ),
  ],
);
