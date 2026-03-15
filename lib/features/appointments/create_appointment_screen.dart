import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import 'appointments_controller.dart';

class CreateAppointmentScreen extends ConsumerStatefulWidget {
  const CreateAppointmentScreen({super.key});

  @override
  ConsumerState<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState
    extends ConsumerState<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  DateTime? _dateTime;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_dateTime == null) return;

    final a = Appointment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      clientName: _nameCtrl.text.trim(),
      service: _serviceCtrl.text.trim(),
      dateTime: _dateTime!,
    );

    ref.read(appointmentsProvider.notifier).add(a);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear turno')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del cliente'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serviceCtrl,
                decoration: const InputDecoration(labelText: 'Servicio'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateTime == null
                          ? 'Selecciona fecha y hora'
                          : _dateTime.toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDateTime,
                    child: const Text('Elegir'),
                  )
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Guardar'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
