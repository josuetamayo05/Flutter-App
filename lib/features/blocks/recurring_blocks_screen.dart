import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'recurring_blocks_controller.dart';

class RecurringBlocksScreen extends ConsumerWidget {
  const RecurringBlocksScreen({super.key});

  String _timeLabel(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _weekdaysLabel(List<int> days) {
    const names = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mié',
      4: 'Jue',
      5: 'Vie',
      6: 'Sáb',
      7: 'Dom',
    };
    final sorted = [...days]..sort();
    return sorted.map((d) => names[d]).join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recurringBlocksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bloqueos recurrentes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/recurring/create'),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const Center(child: Text('No hay bloqueos recurrentes.'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final b = items[i];
                final start = _timeLabel(b.startMinutes);
                final end = _timeLabel(b.startMinutes + b.durationMinutes);

                return ListTile(
                  leading: const Icon(Icons.repeat),
                  title: Text('${b.title} • $start-$end'),
                  subtitle: Text(_weekdaysLabel(b.weekdays)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: b.active,
                        onChanged: (v) => ref
                            .read(recurringBlocksProvider.notifier)
                            .toggle(b.id, v),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(recurringBlocksProvider.notifier)
                            .removeById(b.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
