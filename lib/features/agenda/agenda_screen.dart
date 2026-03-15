import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/time_block.dart';
import '../../utils/dates.dart';
import '../appointments/appointments_controller.dart';
import '../blocks/time_blocks_controller.dart';
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
    String serviceName(String id) => services.firstWhere((s) => s.id == id).name;

    final dfTitle = DateFormat('EEE, dd MMM yyyy');
    final dfTime = DateFormat('HH:mm');

    final appointmentsAsync = ref.watch(appointmentsProvider);
    final blocksAsync = ref.watch(timeBlocksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda • ${dfTitle.format(day)}'),
        actions: [
          IconButton(
            tooltip: 'Bloquear horario',
            icon: const Icon(Icons.event_busy_outlined),
            onPressed: () {
              final d = DateFormat('yyyy-MM-dd').format(day);
              context.go('/block?day=$d');
            },
          ),
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
                    child: const Text('Elegir fecha'),
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
              data: (appts) => blocksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (blocks) {
                  final dayAppts = appts
                      .where((a) => isSameDay(a.dateTime, day))
                      .toList()
                    ..sort((x, y) => x.dateTime.compareTo(y.dateTime));

                  final dayBlocks = blocks
                      .where((b) => isSameDay(b.start, day))
                      .toList()
                    ..sort((x, y) => x.start.compareTo(y.start));

                  final entries = <_AgendaEntry>[];

                  for (final a in dayAppts) {
                    entries.add(
                      _AgendaEntry(
                        start: a.dateTime,
                        end: a.endDateTime,
                        tile: ListTile(
                          leading: const Icon(Icons.event_available_outlined),
                          title: Text('${dfTime.format(a.dateTime)} - ${dfTime.format(a.endDateTime)}'),
                          subtitle: Text('${a.clientName} • ${serviceName(a.serviceId)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref
                                .read(appointmentsProvider.notifier)
                                .removeById(a.id),
                          ),
                        ),
                      ),
                    );
                  }

                  for (final TimeBlock b in dayBlocks) {
                    entries.add(
                      _AgendaEntry(
                        start: b.start,
                        end: b.end,
                        tile: ListTile(
                          leading: const Icon(Icons.block_outlined, color: Colors.red),
                          title: Text('${dfTime.format(b.start)} - ${dfTime.format(b.end)}'),
                          subtitle: Text('Bloqueo: ${b.title}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref
                                .read(timeBlocksProvider.notifier)
                                .removeById(b.id),
                          ),
                        ),
                      ),
                    );
                  }

                  entries.sort((x, y) => x.start.compareTo(y.start));

                  if (entries.isEmpty) {
                    return const Center(child: Text('No hay turnos ni bloqueos para este día.'));
                  }

                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => entries[i].tile,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaEntry {
  final DateTime start;
  final DateTime end;
  final Widget tile;

  _AgendaEntry({
    required this.start,
    required this.end,
    required this.tile,
  });
}