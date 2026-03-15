import 'package:flutter/material.dart';
import 'package:flutter_application_3/models/services_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'appointments_controller.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Turnos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create'),
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final services = ref.watch(servicesProvider);
          String serviceName(String id) =>
              services.firstWhere((s) => s.id == id).name;
          final df = DateFormat('yyyy-MM-dd HH:mm');
          if (items.isEmpty) {
            return const Center(
              child: Text('No hay turnos aún. Crea el primero.'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = items[i];
              return ListTile(
                title: Text('${a.clientName} • ${serviceName(a.serviceId)}'),
                subtitle: Text(
                  '${df.format(a.dateTime)} - ${df.format(a.endDateTime)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      ref.read(appointmentsProvider.notifier).removeById(a.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
