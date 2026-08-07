// Customer application composition root: theme, router and feature wiring only.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/session_store.dart';
import '../../auth/presentation/auth_screens.dart';
import '../../home/presentation/home_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../orders/presentation/confirmation_screen.dart';
import '../../orders/presentation/create_order_screen.dart';
import '../../orders/presentation/order_flow_screens.dart';
import '../../profile/presentation/profile_screen.dart';

Future<void> runCustomerApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sessionStore.restore();
  runApp(const ProviderScope(child: LogiRouteApp()));
}

class LogiRouteApp extends StatelessWidget {
  const LogiRouteApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      scaffoldBackgroundColor: AppColors.panelAlt,
      colorScheme: const ColorScheme.light(primary: AppColors.red),
      textTheme: GoogleFonts.beVietnamProTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.panelAlt,
        elevation: 0,
        centerTitle: true,
      ),
    ),
    routerConfig: createCustomerRouter(),
  );
}

GoRouter createCustomerRouter() => GoRouter(
  initialLocation: appState.value.customerId == null ? '/login' : '/home',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/create-order',
      builder: (context, state) => const CreateOrderScreen(),
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (context, state) => const ConfirmationScreen(),
    ),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(
      path: '/orders/:id/status',
      builder: (context, state) =>
          StatusScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/orders/:id/track',
      builder: (context, state) =>
          TrackingScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/orders/:id/proof',
      builder: (context, state) =>
          ProofScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
