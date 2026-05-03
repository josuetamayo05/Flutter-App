import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import 'work_hours_controller.dart';
import '../../models/work_hours.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _openHour;
  int? _closeHour;
  int? _slotStepMinutes;

  @override
  void initState() {
    super.initState();

    // Cuando workHours cargue/actualice por Realtime, inicializamos los valores locales
    ref.listen<AsyncValue<WorkHours>>(workHoursProvider, (prev, next) {
      final hours = next.valueOrNull;
      if (hours == null) return;
      if (!mounted) return;

      setState(() {
        _openHour ??= hours.openHour;
        _closeHour ??= hours.closeHour;
        _slotStepMinutes ??= hours.slotStepMinutes;
      });
    });
  }

  List<DropdownMenuItem<int>> _hourItems() => List.generate(
        24,
        (h) => DropdownMenuItem(
          value: h,
          child: Text('${h.toString().padLeft(2, '0')}:00'),
        ),
      );

  List<DropdownMenuItem<int>> _stepItems() => const [5, 10, 15, 20, 30, 60]
      .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
      .toList();

  Future<void> _save() async {
    final open = _openHour;
    final close = _closeHour;
    final step = _slotStepMinutes;

    if (open == null || close == null || step == null) return;

    final okHours = await ref
        .read(workHoursProvider.notifier)
        .setHours(openHour: open, closeHour: close);

    if (!mounted) return;

    if (!okHours) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de cierre debe ser mayor que la de apertura'),
        ),
      );
      return;
    }

    final okStep = await ref
        .read(workHoursProvider.notifier)
        .setSlotStepMinutes(step);

    if (!mounted) return;

    if (!okStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intervalo inválido')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajustes guardados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workHoursAsync = ref.watch(workHoursProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: workHoursAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando ajustes: $e')),
        data: (current) {
          final openValue = _openHour ?? current.openHour;
          final closeValue = _closeHour ?? current.closeHour;
          final stepValue = _slotStepMinutes ?? current.slotStepMinutes;

          final canSave = openValue != null && closeValue != null && stepValue != null;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: openValue,
                  decoration: const InputDecoration(labelText: 'Apertura'),
                  items: _hourItems(),
                  onChanged: (v) => setState(() => _openHour = v),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: closeValue,
                  decoration: const InputDecoration(labelText: 'Cierre'),
                  items: _hourItems(),
                  onChanged: (v) => setState(() => _closeHour = v),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: stepValue,
                  decoration: const InputDecoration(labelText: 'Intervalo de turnos'),
                  items: _stepItems(),
                  onChanged: (v) => setState(() => _slotStepMinutes = v),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canSave ? _save : null,
                    child: const Text('Guardar'),
                  ),
                ),

                const SizedBox(height: 12),

                ListTile(
                  leading: const Icon(Icons.repeat),
                  title: const Text('Bloqueos recurrentes'),
                  subtitle: const Text('Ej: almuerzo Lun–Vie'),
                  onTap: () => context.go('/recurring'),
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Tipos de evento'),
                  subtitle: const Text('Duración, color y precio opcional'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/event-types'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar sesión'),
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}