import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../utils/overlaps.dart';
import '../blocks/time_blocks_controller.dart';
import '../settings/work_hours_controller.dart';
import 'appointments_controller.dart';
import '../blocks/recurring_blocks_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../event_types/event_types_controller.dart';
import '../../models/event_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      lastDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 365)),
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

    if (_eventTypeId == null ||
        _selectedDay == null ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona servicio, día y horario')),
      );
      return;
    }

    final types = ref.read(eventTypesProvider).value ?? [];
    final selected = types.firstWhere((t) => t.id == _eventTypeId);

    final a = Appointment(
      id: const Uuid().v4(),
      clientName: _nameCtrl.text.trim(),
      serviceId: selected.id, // <- guarda el id del event type
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
      // Error real de Supabase (RLS, columnas, uuid, etc.)
      debugPrint(
        'PostgrestException: ${e.message} code=${e.code} details=${e.details}',
      );
      debugPrint(
        'SENT (supabase): ${a.toSupabase()}',
      ); // usa tu mapper snake_case

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error BD: ${e.message}')));
    } catch (e) {
      debugPrint('UNKNOWN ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error guardando el turno')));
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
          // AQUÍ ya puedes usar workHours.openHour / closeHour / slotStepMinutes

          return eventTypesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error cargando tipos de evento: $e')),
            data: (eventTypes) {
              final activeTypes = eventTypes.where((e) => e.active).toList();

              EventType? selectedType;
              if (_eventTypeId != null) {
                for (final t in eventTypes) {
                  if (t.id == _eventTypeId) selectedType = t;
                }
              }

              return appointmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (appointments) => blocksAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (blocks) {
                    final busy = <DateTimeRange>[];

                    if (_selectedDay != null) {
                      final day = _selectedDay!;

                      for (final a in appointments) {
                        final sameDay =
                            a.dateTime.year == day.year &&
                            a.dateTime.month == day.month &&
                            a.dateTime.day == day.day;
                        if (sameDay) {
                          busy.add(
                            DateTimeRange(
                              start: a.dateTime,
                              end: a.endDateTime,
                            ),
                          );
                        }
                      }

                      for (final b in blocks) {
                        final sameDay =
                            b.start.year == day.year &&
                            b.start.month == day.month &&
                            b.start.day == day.day;
                        if (sameDay) {
                          busy.add(DateTimeRange(start: b.start, end: b.end));
                        }
                      }

                      final recurring = ref.watch(recurringBlocksProvider);
                      for (final r in recurring) {
                        if (!r.active) continue;
                        if (!r.weekdays.contains(day.weekday)) continue;

                        final start = DateTime(
                          day.year,
                          day.month,
                          day.day,
                        ).add(Duration(minutes: r.startMinutes));
                        final end = start.add(
                          Duration(minutes: r.durationMinutes),
                        );
                        busy.add(DateTimeRange(start: start, end: end));
                      }
                    }

                    final slots = (_selectedDay != null && selectedType != null)
                        ? _availableSlots(
                            day: _selectedDay!,
                            durationMinutes: selectedType.durationMinutes,
                            openHour: workHours.openHour,
                            closeHour: workHours.closeHour,
                            stepMinutes: workHours
                                .slotStepMinutes, // <-- aquí usas el intervalo del usuario
                            busy: busy,
                          )
                        : <DateTime>[];

                    // ... el resto de tu UI igual ...
                    return /* tu Padding/Form/etc */;
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
