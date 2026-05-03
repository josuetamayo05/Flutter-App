import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../utils/overlaps.dart';
import '../../models/time_block.dart';
import '../appointments/appointments_controller.dart';
import '../settings/work_hours_controller.dart';
import 'time_blocks_controller.dart';
import 'recurring_blocks_controller.dart';

class CreateBlockScreen extends ConsumerStatefulWidget {
  final DateTime? initialDay; // date-only
  const CreateBlockScreen({super.key, this.initialDay});

  @override
  ConsumerState<CreateBlockScreen> createState() => _CreateBlockScreenState();
}

class _CreateBlockScreenState extends ConsumerState<CreateBlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController(text: 'Almuerzo');

  DateTime? _day;
  DateTime? _start;
  int _durationMinutes = 60;


  @override
  void initState() {
    super.initState();
    if (widget.initialDay != null) {
      _day = DateTime(
        widget.initialDay!.year,
        widget.initialDay!.month,
        widget.initialDay!.day,
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  List<DateTime> _startSlots({
    required DateTime day,
    required int openHour,
    required int closeHour,
    required int stepMinutes,
    required List<DateTimeRange> busy,
    required int durationMinutes,
  }) {
    final open = DateTime(day.year, day.month, day.day, openHour);
    final close = DateTime(day.year, day.month, day.day, closeHour);

    final result = <DateTime>[];
    for (
      var t = open;
      !t.add(Duration(minutes: durationMinutes)).isAfter(close);
      t = t.add(Duration(minutes: stepMinutes))
    ) {
      final tEnd = t.add(Duration(minutes: durationMinutes));
      final conflict = busy.any((r) => overlaps(t, tEnd, r.start, r.end));
      if (!conflict) result.add(t);
    }
    return result;
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 365)),
      initialDate: _day ?? DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      _day = DateTime(picked.year, picked.month, picked.day);
      _start = null;
    });
  }

  Future<void> _save(List<DateTimeRange> busy) async {
    if (!_formKey.currentState!.validate()) return;
    if (_day == null || _start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona día y hora de inicio')),
      );
      return;
    }

    final end = _start!.add(Duration(minutes: _durationMinutes));
    final conflict = busy.any((r) => overlaps(_start!, end, r.start, r.end));
    if (conflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese horario ya está ocupado')),
      );
      return;
    }

    final block = TimeBlock(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      start: _start!,
      end: end,
    );

    await ref.read(timeBlocksProvider.notifier).add(block);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final workHoursAsync = ref.watch(workHoursProvider);
    final apptAsync = ref.watch(appointmentsProvider);
    final blocksAsync = ref.watch(timeBlocksProvider);

    final dfDay = DateFormat('yyyy-MM-dd');
    final dfTime = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Bloquear horario')),
      body: workHoursAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando horario: $e')),
        data: (workHours) {
          return apptAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (appts) => blocksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (blocks) {
                final day = _day;
                final busy = <DateTimeRange>[];
                final recurring = ref.watch(recurringBlocksProvider);

                if (day != null) {
                  for (final a in appts) {
                    if (a.dateTime.year == day.year &&
                        a.dateTime.month == day.month &&
                        a.dateTime.day == day.day) {
                      busy.add(DateTimeRange(start: a.dateTime, end: a.endDateTime));
                    }
                  }

                  for (final b in blocks) {
                    if (b.start.year == day.year &&
                        b.start.month == day.month &&
                        b.start.day == day.day) {
                      busy.add(DateTimeRange(start: b.start, end: b.end));
                    }
                  }

                  for (final r in recurring) {
                    if (!r.active) continue;
                    if (!r.weekdays.contains(day.weekday)) continue;

                    final start = DateTime(day.year, day.month, day.day)
                        .add(Duration(minutes: r.startMinutes));
                    final end = start.add(Duration(minutes: r.durationMinutes));
                    busy.add(DateTimeRange(start: start, end: end));
                  }
                }

                final slots = (day == null)
                    ? <DateTime>[]
                    : _startSlots(
                        day: day,
                        openHour: workHours.openHour,
                        closeHour: workHours.closeHour,
                        stepMinutes: workHours.slotStepMinutes, // <-- intervalo del usuario
                        busy: busy,
                        durationMinutes: _durationMinutes,
                      );

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Motivo (ej: Almuerzo)',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                day == null
                                    ? 'Selecciona un día'
                                    : 'Día: ${dfDay.format(day)}',
                              ),
                            ),
                            TextButton(
                              onPressed: _pickDay,
                              child: const Text('Elegir día'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _durationMinutes,
                          decoration: const InputDecoration(labelText: 'Duración'),
                          items: const [30, 60, 90, 120]
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text('$m min'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _durationMinutes = v;
                              _start = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        if (day != null) ...[
                          Text('Inicio (cada ${workHours.slotStepMinutes} min):'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: slots.map((t) {
                              final selected = _start == t;
                              return ChoiceChip(
                                label: Text(dfTime.format(t)),
                                selected: selected,
                                onSelected: (_) => setState(() => _start = t),
                              );
                            }).toList(),
                          ),
                          if (slots.isEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('No hay horarios libres para ese día.'),
                          ],
                        ],
                        const Spacer(),
                        FilledButton(
                          onPressed: () => _save(busy),
                          child: const Text('Guardar bloqueo'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
