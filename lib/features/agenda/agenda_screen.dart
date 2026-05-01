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

  Future<bool> _confirmDelete(BuildContext context, {required String title}) async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmar'),
            content: Text('¿Eliminar $title?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);

    final services = ref.watch(servicesProvider);
    String serviceName(String id) => services.firstWhere((s) => s.id == id).name;

    final dfTitle = DateFormat('EEE, dd MMM yyyy');
    final dfDayName = DateFormat('EEE', 'es');
    final dfTime = DateFormat('HH:mm');

    final appointmentsAsync = ref.watch(appointmentsProvider);
    final blocksAsync = ref.watch(timeBlocksProvider);

    final cs = Theme.of(context).colorScheme;

    final dayKey = DateFormat('yyyy-MM-dd').format(day);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agenda', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              dfTitle.format(day),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Elegir fecha',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _pickDay(context, ref, day),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            onSelected: (value) {
              switch (value) {
                case 'block':
                  context.go('/block?day=$dayKey');
                  return;
                case 'all':
                  context.go('/all');
                  return;
                case 'settings':
                  context.go('/settings');
                  return;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'block', child: Text('Bloquear horario')),
              PopupMenuItem(value: 'all', child: Text('Ver todos')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'settings', child: Text('Ajustes')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create?day=$dayKey'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cita'),
      ),
      body: Column(
        children: [
          // Selector horizontal de días (7 días alrededor del seleccionado)
          _DayStrip(
            day: day,
            dfDayName: dfDayName,
            onPrev: () => ref.read(selectedDayProvider.notifier).state = day.subtract(const Duration(days: 1)),
            onNext: () => ref.read(selectedDayProvider.notifier).state = day.add(const Duration(days: 1)),
            onSelect: (d) => ref.read(selectedDayProvider.notifier).state = dateOnly(d),
          ),

          // Contenido principal
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(message: 'Error cargando citas: $e'),
              data: (appts) => blocksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(message: 'Error cargando bloqueos: $e'),
                data: (blocks) {
                  final dayAppts = appts.where((a) => isSameDay(a.dateTime, day)).toList()
                    ..sort((x, y) => x.dateTime.compareTo(y.dateTime));

                  final dayBlocks = blocks.where((b) => isSameDay(b.start, day)).toList()
                    ..sort((x, y) => x.start.compareTo(y.start));

                  final entries = <_AgendaEntry>[];

                  for (final a in dayAppts) {
                    entries.add(
                      _AgendaEntry(
                        start: a.dateTime,
                        tile: _AgendaCard(
                          barColor: cs.primary,
                          time: '${dfTime.format(a.dateTime)} - ${dfTime.format(a.endDateTime)}',
                          title: serviceName(a.serviceId),
                          subtitle: a.clientName,
                          leadingIcon: Icons.event_available_outlined,
                          onDelete: () async {
                            final ok = await _confirmDelete(context, title: 'esta cita');
                            if (!ok) return;
                            await ref.read(appointmentsProvider.notifier).removeById(a.id);
                          },
                        ),
                      ),
                    );
                  }

                  for (final TimeBlock b in dayBlocks) {
                    entries.add(
                      _AgendaEntry(
                        start: b.start,
                        tile: _AgendaCard(
                          barColor: Colors.redAccent,
                          time: '${dfTime.format(b.start)} - ${dfTime.format(b.end)}',
                          title: 'Bloqueo',
                          subtitle: b.title,
                          leadingIcon: Icons.block_outlined,
                          onDelete: () async {
                            final ok = await _confirmDelete(context, title: 'este bloqueo');
                            if (!ok) return;
                            await ref.read(timeBlocksProvider.notifier).removeById(b.id);
                          },
                        ),
                      ),
                    );
                  }

                  entries.sort((a, b) => a.start.compareTo(b.start));

                  return RefreshIndicator(
                    onRefresh: () async {
                      // Con Realtime no es necesario, pero es útil como fallback
                      ref.invalidate(appointmentsProvider);
                      ref.invalidate(timeBlocksProvider);
                    },
                    child: entries.isEmpty
                        ? const _EmptyState(
                            title: 'No hay eventos para este día',
                            subtitle: 'Crea una cita o agrega un bloqueo.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => entries[i].tile,
                          ),
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

class _DayStrip extends StatelessWidget {
  final DateTime day;
  final DateFormat dfDayName;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  const _DayStrip({
    required this.day,
    required this.dfDayName,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final days = List.generate(7, (i) => day.add(Duration(days: i - 3)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final d = dateOnly(days[i]);
                  final selected = isSameDay(d, day);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onSelect(d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 66,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? cs.primary : cs.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? Colors.transparent : Colors.white10,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dfDayName.format(d).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? cs.background : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: selected ? cs.background : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final Color barColor;
  final String time;
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Future<void> Function() onDelete;

  const _AgendaCard({
    required this.barColor,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Icon(leadingIcon, color: cs.onSurface.withOpacity(0.9)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        Icon(Icons.event_note_outlined, size: 56, color: Colors.grey.shade500),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _AgendaEntry {
  final DateTime start;
  final Widget tile;

  _AgendaEntry({required this.start, required this.tile});
}