import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/appointment.dart';

class AppointmentsSupabaseRepo {
  final SupabaseClient client;
  const AppointmentsSupabaseRepo(this.client);

  Future<List<Appointment>> fetchAll() async {
    final data = await client
        .from('appointments')
        .select()
        .order('date_time', ascending: true);

    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(_fromRow).toList();
  }

  Future<Appointment> create({
    required String clientName,
    required String serviceId,
    required int durationMinutes,
    required DateTime dateTime,
  }) async {
    final id = const Uuid().v4();

    final row = await client
        .from('appointments')
        .insert({
          'id': id, // uuid válido
          'client_name': clientName,
          'service_id': serviceId,
          'duration_minutes': durationMinutes,
          'date_time': dateTime.toIso8601String(),
          // user_id NO hace falta: por default auth.uid() y RLS
        })
        .select()
        .single();

    return _fromRow(row as Map<String, dynamic>);
  }

  Future<void> deleteById(String id) async {
    await client.from('appointments').delete().eq('id', id);
  }

  Appointment _fromRow(Map<String, dynamic> r) {
    return Appointment(
      id: r['id'] as String,
      clientName: r['client_name'] as String,
      serviceId: r['service_id'] as String,
      durationMinutes: r['duration_minutes'] as int,
      dateTime: DateTime.parse(r['date_time'] as String),
    );
  }
}