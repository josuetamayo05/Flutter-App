import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/services_provider.dart';
import 'appointments_controller.dart';

class CreateAppointmentScreen extends ConsumerStatefulWidget {
  const CreateAppointmentScreen({super.key});

  @override
  ConsumerState<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends ConsumerState<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  String? _serviceId;
  DateTime? _selectedDay;       // solo fecha (sin hora)
  DateTime? _selectedDateTime;  // fecha + hora (slot)

  static const _slotStepMinutes = 30;
  static const _openHour = 9;
  static const _closeHour = 18;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 365)),
      initialDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;

    setState(() {
      _selectedDay = DateTime(picked.year, picked.month, picked.day);
      _selectedDateTime = null; // reset slot
    });
  }

  List<DateTime> _availableSlots({
    required DateTime day,
    required int durationMinutes,
    required List<Appointment> existing,
  }) {
    final open = DateTime(day.year, day.month, day.day, _openHour, 0);
    final close = DateTime(day.year, day.month, day.day, _closeHour, 0);

    bool overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
      return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
    }

    final slots = <DateTime>[];
    for (var t = open;
        !t.add(Duration(minutes: durationMinutes)).isAfter(close);
        t = t.add(const Duration(minutes: _slotStepMinutes))) {
      final tEnd = t.add(Duration(minutes: durationMinutes));

      final conflict = existing.any((b) {
        final bStart = b.dateTime;
        final bEnd = b.endDateTime;
        return overlaps(t, tEnd, bStart, bEnd);
      });

      if (!conflict) slots.add(t);
    }

    return slots;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_serviceId == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona servicio y horario')),
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

    final ok = await ref.read(appointmentsProvider.notifier).add(a);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese horario ya está ocupado')),
      );
      return;
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final dfDay = DateFormat('yyyy-MM-dd');
    final dfTime = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Crear turno')),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (appointments) {
          final selectedService = _serviceId == null
              ? null
              : services.firstWhere((s) => s.id == _serviceId);

          final slots = (_selectedDay != null && selectedService != null)
              ? _availableSlots(
                  day: _selectedDay!,
                  durationMinutes: selectedService.durationMinutes,
                  existing: appointments.where((a) {
                    // solo turnos del mismo día
                    return a.dateTime.year == _selectedDay!.year &&
                        a.dateTime.month == _selectedDay!.month &&
                        a.dateTime.day == _selectedDay!.day;
                  }).toList(),
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
                        _selectedDateTime = null; // reset slot
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
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_selectedDay != null && selectedService != null) ...[
                    const Text('Horarios disponibles (cada 30 min):'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((t) {
                        final selected = _selectedDateTime == t;
                        return ChoiceChip(
                          label: Text(dfTime.format(t)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedDateTime = t);
                          },
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
  }
}