import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/event_type.dart';

class EventTypesSupabaseRepo {
  final SupabaseClient client;
  const EventTypesSupabaseRepo(this.client);

  Future<List<EventType>> fetchAll() async {
    final data = await client
        .from('event_types')
        .select()
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);

    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(EventType.fromSupabase).toList();
  }

  Stream<List<EventType>> streamAll(String userId) {
    return client
        .from('event_types')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sort_order', ascending: true)
        .map((rows) => rows.map(EventType.fromSupabase).toList());
  }

  Future<void> create(EventType e) async {
    await client.from('event_types').insert(e.toSupabase());
  }

  Future<void> update(EventType e) async {
    await client.from('event_types').update(e.toSupabase()).eq('id', e.id);
  }

  Future<void> deleteById(String id) async {
    await client.from('event_types').delete().eq('id', id);
  }

  Future<void> setActive(String id, bool active) async {
    await client.from('event_types').update({'active': active}).eq('id', id);
  }
}