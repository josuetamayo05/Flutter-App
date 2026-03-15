import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../utils/dates.dart';
import '../appointments/appointments_controller.dart';
import '../../models/services_provider.dart';
import 'selected_day_provider.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  Future<void> _pickDay(BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(current.year - 1),
      lastDate: DateTime(current.year + 2),
      initialDate: current,
    );
    if (picked == null) return;
    ref.read(selectedDayProvider.notifier).state = dateOnly(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final services = ref.watch(servicesProvider);
    final dfTitle = DateFormat('EEE, dd MMM yyyy');
    final dfTime = DateFormat('HH:mm');

    String serviceName(String id) =>
        services.firstWhere((s) => s.id == id).name;

    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda • ${dfTitle.format(day)}'),
        actions: [
          IconButton(
            tooltip: 'Ver todos',
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () => context.go('/all'),
          ),
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final d = DateFormat('yyyy-MM-dd').format(day);
          context.go('/create?day=$d');
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Selector simple de día
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => ref.read(selectedDayProvider.notifier).state =
                      day.subtract(const Duration(days: 1)),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDay(context, ref, day),
                    child: Text('Elegir fecha'),
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(selectedDayProvider.notifier).state =
                      day.add(const Duration(days: 1)),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final items = all
                    .where((a) => isSameDay(a.dateTime, day))
                    .toList()
                  ..sort((x, y) => x.dateTime.compareTo(y.dateTime));

                if (items.isEmpty) {
                  return const Center(child: Text('No hay turnos para este día.'));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final a = items[i];
                    return ListTile(
                      title: Text('${dfTime.format(a.dateTime)} - ${dfTime.format(a.endDateTime)}'),
                      subtitle: Text('${a.clientName} • ${serviceName(a.serviceId)}'),
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
            ),
          ),
        ],
      ),
    );
  }
}