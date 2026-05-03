import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'work_hours_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _openHour;
  int? _closeHour;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hours = ref.read(workHoursProvider);
    _openHour ??= hours.openHour;
    _closeHour ??= hours.closeHour;
  }

  List<DropdownMenuItem<int>> _hourItems() => List.generate(
        24,
        (h) => DropdownMenuItem(value: h, child: Text(h.toString().padLeft(2, '0') + ':00')),
      );

  Future<void> _save() async {
    final ok = await ref
        .read(workHoursProvider.notifier)
        .setHours(openHour: _openHour!, closeHour: _closeHour!);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de cierre debe ser mayor que la de apertura')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Horario guardado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solo para mostrar el valor actual si cambia desde fuera:
    final current = ref.watch(workHoursProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: _openHour ?? current.openHour,
              decoration: const InputDecoration(labelText: 'Apertura'),
              items: _hourItems(),
              onChanged: (v) => setState(() => _openHour = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _closeHour ?? current.closeHour,
              decoration: const InputDecoration(labelText: 'Cierre'),
              items: _hourItems(),
              onChanged: (v) => setState(() => _closeHour = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_openHour == null || _closeHour == null) ? null : _save,
                child: const Text('Guardar'),
              ),
            ),
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
      ),
    );
  }
}