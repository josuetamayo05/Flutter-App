import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/recurring_block.dart';
import 'recurring_blocks_controller.dart';
import 'package:go_router/go_router.dart';

class CreateRecurringBlockScreen extends ConsumerStatefulWidget {
  const CreateRecurringBlockScreen({super.key});

  @override
  ConsumerState<CreateRecurringBlockScreen> createState() => _CreateRecurringBlockScreenState();
}

class _CreateRecurringBlockScreenState extends ConsumerState<CreateRecurringBlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController(text: 'Almuerzo');

  final Set<int> _weekdays = {1,2,3,4,5}; // Lun-Vie por defecto
  int _startMinutes = 12 * 60; // 12:00
  int _durationMinutes = 60;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<int>> _timeItems() {
    // cada 30 min
    final items = <DropdownMenuItem<int>>[];
    for (int m = 0; m < 24 * 60; m += 30) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      items.add(DropdownMenuItem(value: m, child: Text('$h:$mm')));
    }
    return items;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día de la semana')),
      );
      return;
    }

    final block = RecurringBlock(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      weekdays: _weekdays.toList(),
      startMinutes: _startMinutes,
      durationMinutes: _durationMinutes,
      active: true,
    );

    await ref.read(recurringBlocksProvider.notifier).add(block);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    const names = {1:'Lun',2:'Mar',3:'Mié',4:'Jue',5:'Vie',6:'Sáb',7:'Dom'};

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo bloqueo recurrente')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Motivo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              const Text('Días:'),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final d = i + 1;
                  final selected = _weekdays.contains(d);
                  return FilterChip(
                    label: Text(names[d]!),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) _weekdays.add(d);
                        else _weekdays.remove(d);
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _startMinutes,
                decoration: const InputDecoration(labelText: 'Hora inicio'),
                items: _timeItems(),
                onChanged: (v) => setState(() => _startMinutes = v ?? _startMinutes),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _durationMinutes,
                decoration: const InputDecoration(labelText: 'Duración'),
                items: const [30, 60, 90, 120]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                    .toList(),
                onChanged: (v) => setState(() => _durationMinutes = v ?? _durationMinutes),
              ),

              const Spacer(),
              FilledButton(
                onPressed: _save,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}