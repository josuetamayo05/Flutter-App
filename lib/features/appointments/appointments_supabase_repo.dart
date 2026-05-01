import 'package:supabase_flutter/supabase_flutter.dart';
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
    return list.map(Appointment.fromSupabase).toList();
  }

  Future<void> create(Appointment a) async {
    await client.from('appointments').insert(a.toSupabase());
  }

  Future<void> deleteById(String id) async {
    await client.from('appointments').delete().eq('id', id);
  }

  Stream<List<Appointment>> streamAll(String userId) {
    return client
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date_time', ascending: true)
        .map((rows) => rows.map(Appointment.fromSupabase).toList());
  }  
}