import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'event_types_controller.dart';
import 'event_type_form_sheet.dart';

class EventTypesScreen extends ConsumerWidget {
  const EventTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(eventTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tipos de evento')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => EventTypeFormSheet(
            initial: null,
            onSave: (draft) async {
              final item = draft.copyWith(
                id: const Uuid().v4(),
                sortOrder: DateTime.now().millisecondsSinceEpoch,
              );
              await ref.read(eventTypesProvider.notifier).createEventType(item);
            },
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Crea tu primer tipo de evento.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final e = items[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    width: 10,
                    height: 42,
                    decoration: BoxDecoration(
                      color: e.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${e.durationMinutes} min'
                      '${e.priceCents != null ? ' • ${(e.priceCents! / 100).toStringAsFixed(2)}' : ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: e.active,
                        onChanged: (v) => ref.read(eventTypesProvider.notifier).setEventTypeActive(e.id, v),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => EventTypeFormSheet(
                            initial: e,
                            onSave: (updated) async {
                              await ref.read(eventTypesProvider.notifier).updateEventType(updated);
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref.read(eventTypesProvider.notifier).deleteEventType(e.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}