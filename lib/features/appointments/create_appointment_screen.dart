import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../models/appointment.dart';
import '../../utils/overlaps.dart';
import '../blocks/time_blocks_controller.dart';
import '../../models/services_provider.dart';
import '../settings/work_hours_controller.dart';
import 'appointments_controller.dart';
import '../blocks/recurring_blocks_controller.dart';

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

  String? _serviceId;
  DateTime? _selectedDay; // date-only
  DateTime? _selectedDateTime; // slot elegido (fecha+hora)

  static const _slotStepMinutes = 30;

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
    required List<DateTimeRange> busy,
  }) {
    final open = DateTime(day.year, day.month, day.day, openHour, 0);
    final close = DateTime(day.year, day.month, day.day, closeHour, 0);

    final slots = <DateTime>[];

    for (var t = open;
        !t.add(Duration(minutes: durationMinutes)).isAfter(close);
        t = t.add(const Duration(minutes: _slotStepMinutes))) {
      final tEnd = t.add(Duration(minutes: durationMinutes));

      final conflict = busy.any((r) => overlaps(t, tEnd, r.start, r.end));
      if (!conflict) slots.add(t);
    }

    return slots;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_serviceId == null || _selectedDay == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona servicio, día y horario')),
      );
      return;
    }

    final services = ref.read(servicesProvider);
    final service = services.firstWhere((s) => s.id == _serviceId);

    final a = Appointment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      clientName: _nameCtrl.text.trim(),
      serviceId: service.id,
      durationMinutes: service.durationMinutes,
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
    } on DioException catch (e) {
      debugPrint('TYPE: ${e.type}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('ERROR: ${e.error}');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('RESP DATA: ${e.response?.data}');
      debugPrint('SENT JSON: ${a.toJson()}');
    }

  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final workHours = ref.watch(workHoursProvider);

    final appointmentsAsync = ref.watch(appointmentsProvider);
    final blocksAsync = ref.watch(timeBlocksProvider);

    final dfDay = DateFormat('yyyy-MM-dd');
    final dfTime = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Crear turno')),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (appointments) => blocksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (blocks) {
            final selectedService = _serviceId == null
                ? null
                : services.firstWhere((s) => s.id == _serviceId);

            // Busy ranges del día: turnos + bloqueos
            final busy = <DateTimeRange>[];

            if (_selectedDay != null) {
              final day = _selectedDay!;
              for (final a in appointments) {
                final sameDay =
                    a.dateTime.year == day.year &&
                    a.dateTime.month == day.month &&
                    a.dateTime.day == day.day;
                if (sameDay) {
                  busy.add(DateTimeRange(start: a.dateTime, end: a.endDateTime));
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
            }
            
            final recurring = ref.watch(recurringBlocksProvider);

            if (_selectedDay != null) {
              final day = _selectedDay!;
              for (final r in recurring) {
                if (!r.active) continue;
                if (!r.weekdays.contains(day.weekday)) continue;

                final start = DateTime(day.year, day.month, day.day)
                    .add(Duration(minutes: r.startMinutes));
                final end = start.add(Duration(minutes: r.durationMinutes));
                busy.add(DateTimeRange(start: start, end: end));
              }
            }

            final slots = (_selectedDay != null && selectedService != null)
                ? _availableSlots(
                    day: _selectedDay!,
                    durationMinutes: selectedService.durationMinutes,
                    openHour: workHours.openHour,
                    closeHour: workHours.closeHour,
                    busy: busy,
                  )
                : <DateTime>[];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre del cliente'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _serviceId,
                      decoration: const InputDecoration(labelText: 'Servicio'),
                      items: services
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.name} (${s.durationMinutes} min)'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _serviceId = v;
                          _selectedDateTime = null;
                        });
                      },
                    ),
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

                    if (_selectedDay != null && selectedService != null) ...[
                      Text(
                        'Horarios disponibles (cada 30 min) • '
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
      ),
    );
  }
}