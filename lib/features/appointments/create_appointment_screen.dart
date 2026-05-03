import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/appointment.dart';
import '../../models/event_type.dart';
import '../../utils/overlaps.dart';
import '../appointments/appointments_controller.dart';
import '../blocks/recurring_blocks_controller.dart';
import '../blocks/time_blocks_controller.dart';
import '../event_types/event_types_controller.dart';
import '../settings/work_hours_controller.dart';

class CreateAppointmentScreen extends ConsumerStatefulWidget {
  final DateTime? initialDay; // date-only (yyyy-mm-dd)
  const CreateAppointmentScreen({super.key, this.initialDay});

  @override
  ConsumerState<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState
    extends ConsumerState<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  String? _eventTypeId;
  DateTime? _selectedDay; // date-only
  DateTime? _selectedDateTime; // slot elegido (fecha+hora)

  @override
  void initState() {
    super.initState();
    if (widget.initialDay != null) {
      _selectedDay = DateTime(
        widget.initialDay!.year,
        widget.initialDay!.month,
        widget.initialDay!.day,
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final initial = _selectedDay ?? DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 365)),
      initialDate: initial,
    );
    if (picked == null) return;

    setState(() {
      _selectedDay = DateTime(picked.year, picked.month, picked.day);
      _selectedDateTime = null;
    });
  }

  List<DateTime> _availableSlots({
    required DateTime day,
    required int durationMinutes,
    required int openHour,
    required int closeHour,
    required int stepMinutes,
    required List<DateTimeRange> busy,
  }) {
    final open = DateTime(day.year, day.month, day.day, openHour, 0);
    final close = DateTime(day.year, day.month, day.day, closeHour, 0);

    final slots = <DateTime>[];

    for (
      var t = open;
      !t.add(Duration(minutes: durationMinutes)).isAfter(close);
      t = t.add(Duration(minutes: stepMinutes))
    ) {
      final tEnd = t.add(Duration(minutes: durationMinutes));
      final conflict = busy.any((r) => overlaps(t, tEnd, r.start, r.end));
      if (!conflict) slots.add(t);
    }

    return slots;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_eventTypeId == null || _selectedDay == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona servicio, día y horario')),
      );
      return;
    }

    // Evita "Bad state: No element" si aún está cargando o si no existe el tipo
    final types = await ref.read(eventTypesProvider.future);
    EventType? selected;
    for (final t in types) {
      if (t.id == _eventTypeId) {
        selected = t;
        break;
      }
    }

    if (selected == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El tipo de evento seleccionado ya no existe')),
      );
      return;
    }

    final a = Appointment(
      id: const Uuid().v4(),
      clientName: _nameCtrl.text.trim(),
      serviceId: selected.id,
      durationMinutes: selected.durationMinutes,
      dateTime: _selectedDateTime!,
    );

    try {
      final ok = await ref.read(appointmentsProvider.notifier).add(a);
      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese horario ya está ocupado')),
        );
        return;
      }

      context.pop();
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException: ${e.message} code=${e.code} details=${e.details}');
      debugPrint('SENT (supabase): ${a.toSupabase()}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error BD: ${e.message}')),
      );
    } catch (e) {
      debugPrint('UNKNOWN ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error guardando el turno')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workHoursAsync = ref.watch(workHoursProvider);
    final eventTypesAsync = ref.watch(eventTypesProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final blocksAsync = ref.watch(timeBlocksProvider);

    final dfDay = DateFormat('yyyy-MM-dd');
    final dfTime = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Crear turno')),
      body: workHoursAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando horario: $e')),
        data: (workHours) {
          return eventTypesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error cargando tipos de evento: $e')),
            data: (eventTypes) {
              final activeTypes = eventTypes.where((e) => e.active).toList();

              EventType? selectedType;
              if (_eventTypeId != null) {
                for (final t in eventTypes) {
                  if (t.id == _eventTypeId) {
                    selectedType = t;
                    break;
                  }
                }
              }

              return appointmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error cargando citas: $e')),
                data: (appointments) => blocksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error cargando bloqueos: $e')),
                  data: (blocks) {
                    final busy = <DateTimeRange>[];

                    if (_selectedDay != null) {
                      final day = _selectedDay!;

                      // Turnos del día
                      for (final a in appointments) {
                        final sameDay = a.dateTime.year == day.year &&
                            a.dateTime.month == day.month &&
                            a.dateTime.day == day.day;
                        if (sameDay) {
                          busy.add(DateTimeRange(start: a.dateTime, end: a.endDateTime));
                        }
                      }

                      // Bloqueos puntuales del día
                      for (final b in blocks) {
                        final sameDay = b.start.year == day.year &&
                            b.start.month == day.month &&
                            b.start.day == day.day;
                        if (sameDay) {
                          busy.add(DateTimeRange(start: b.start, end: b.end));
                        }
                      }

                      // Bloqueos recurrentes del día
                      final recurring = ref.watch(recurringBlocksProvider);
                      for (final r in recurring) {
                        if (!r.active) continue;
                        if (!r.weekdays.contains(day.weekday)) continue;

                        final start = DateTime(day.year, day.month, day.day)
                            .add(Duration(minutes: r.startMinutes));
                        final end = start.add(Duration(minutes: r.durationMinutes));
                        busy.add(DateTimeRange(start: start, end: end));
                      }
                    }

                    final slots = (_selectedDay != null && selectedType != null)
                        ? _availableSlots(
                            day: _selectedDay!,
                            durationMinutes: selectedType.durationMinutes,
                            openHour: workHours.openHour,
                            closeHour: workHours.closeHour,
                            stepMinutes: workHours.slotStepMinutes,
                            busy: busy,
                          )
                        : <DateTime>[];

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del cliente',
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              value: _eventTypeId,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de evento',
                              ),
                              items: activeTypes
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text('${t.name} (${t.durationMinutes} min)'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _eventTypeId = v;
                                  _selectedDateTime = null;
                                });
                              },
                            ),

                            if (activeTypes.isEmpty) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => context.go('/event-types'),
                                child: const Text('Crear tipos de evento'),
                              ),
                            ],

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedDay == null
                                        ? 'Selecciona un día'
                                        : 'Día: ${dfDay.format(_selectedDay!)}',
                                  ),
                                ),
                                TextButton(
                                  onPressed: _pickDay,
                                  child: const Text('Elegir día'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (_selectedDay != null && _eventTypeId != null) ...[
                              Text(
                                'Horarios disponibles (cada ${workHours.slotStepMinutes} min) • '
                                '${workHours.openHour.toString().padLeft(2, '0')}:00 - '
                                '${workHours.closeHour.toString().padLeft(2, '0')}:00',
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: slots.map((t) {
                                  final selected = _selectedDateTime == t;
                                  return ChoiceChip(
                                    label: Text(dfTime.format(t)),
                                    selected: selected,
                                    onSelected: (_) => setState(() => _selectedDateTime = t),
                                  );
                                }).toList(),
                              ),
                              if (slots.isEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('No hay horarios disponibles para ese día/servicio.'),
                              ],
                            ],

                            const Spacer(),

                            FilledButton(
                              onPressed: _submit,
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}