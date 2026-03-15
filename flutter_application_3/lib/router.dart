import 'package:go_router/go_router.dart';
import 'features/appointments/appointments_screen.dart';
import 'features/appointments/create_appointment_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const AppointmentsScreen(),
      routes: [
        GoRoute(
          path: 'create',
          builder: (_, __) => const CreateAppointmentScreen(),
        ),
      ],
    ),
  ],
);