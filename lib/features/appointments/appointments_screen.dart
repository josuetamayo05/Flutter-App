import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../event_types/event_types_controller.dart';
import 'appointments_controller.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(appointmentsProvider);
    final eventTypesAsync = ref.watch(eventTypesProvider);

    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create'),
        child: const Icon(Icons.add),
      ),
      body: eventTypesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando tipos de evento: $e')),
        data: (eventTypes) {
          final typesById = {for (final t in eventTypes) t.id: t};
          String eventName(String id) => typesById[id]?.name ?? 'Evento';

          return itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text('No hay turnos aún. Crea el primero.'),
                );
              }

              // opcional: ordenar por fecha
              final sorted = [...items]..sort((a, b) => a.dateTime.compareTo(b.dateTime));

              return ListView.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final a = sorted[i];
                  return ListTile(
                    title: Text('${a.clientName} • ${eventName(a.serviceId)}'),
                    subtitle: Text(
                      '${df.format(a.dateTime)} - ${df.format(a.endDateTime)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(appointmentsProvider.notifier)
                          .removeById(a.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}