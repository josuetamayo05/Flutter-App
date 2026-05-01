import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/splash_screen.dart';

import 'features/agenda/agenda_screen.dart';
import 'features/appointments/appointments_screen.dart';
import 'features/appointments/create_appointment_screen.dart';
import 'features/blocks/create_block_screen.dart';
import 'features/blocks/recurring_blocks_screen.dart';
import 'features/blocks/create_recurring_block_screen.dart';
import 'features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  final isAuthLoading = auth.isLoading;
  final isLoggedIn = auth.valueOrNull != null;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      final goingToSplash = loc == '/splash';
      final goingToLogin = loc == '/login';
      final goingToRegister = loc == '/register';

      // 1) Mientras carga sesión: manda a splash
      if (isAuthLoading) {
        return goingToSplash ? null : '/splash';
      }

      // 2) Ya no está cargando: evita quedarse en splash
      if (goingToSplash) {
        return isLoggedIn ? '/' : '/login';
      }

      // 3) No logueado: solo permite login/register
      if (!isLoggedIn && !(goingToLogin || goingToRegister)) {
        return '/login';
      }

      // 4) Logueado: no debería ver login/register
      if (isLoggedIn && (goingToLogin || goingToRegister)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const AgendaScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, state) {
              final dayStr = state.uri.queryParameters['day'];
              final initialDay = dayStr == null ? null : DateTime.parse(dayStr);
              return CreateAppointmentScreen(initialDay: initialDay);
            },
          ),
          GoRoute(
            path: 'block',
            builder: (_, state) {
              final dayStr = state.uri.queryParameters['day'];
              final initialDay = dayStr == null ? null : DateTime.parse(dayStr);
              return CreateBlockScreen(initialDay: initialDay);
            },
          ),
          GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: 'all', builder: (_, __) => const AppointmentsScreen()),
          GoRoute(path: 'recurring', builder: (_, __) => const RecurringBlocksScreen()),
          GoRoute(path: 'recurring/create', builder: (_, __) => const CreateRecurringBlockScreen()),
        ],
      ),
    ],
  );
});