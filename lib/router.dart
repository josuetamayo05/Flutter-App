import 'package:go_router/go_router.dart';

import 'features/agenda/agenda_screen.dart';
import 'features/appointments/appointments_screen.dart';
import 'features/appointments/create_appointment_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/blocks/create_block_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const AgendaScreen(),
      routes: [
        GoRoute(
          path: 'create',
          builder: (_, state) {
            final dayStr = state.uri.queryParameters['day'];
            final initialDay = dayStr == null ? null : DateTime.parse(dayStr);
            return CreateAppointmentScreen(initialDay: initialDay,);
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'all',
          builder: (_, __) => const AppointmentsScreen(),
        ),
        GoRoute(
          path: 'block',
          builder: (_, state) {
            final dayStr = state.uri.queryParameters['day'];
            final initialDay = dayStr == null ? null : DateTime.parse(dayStr);
            return CreateBlockScreen(initialDay: initialDay);
          },
        ),
      ],
    ),
  ],
);