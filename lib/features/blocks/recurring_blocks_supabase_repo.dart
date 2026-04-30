import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recurring_block.dart';

class RecurringBlocksSupabaseRepo {
  final SupabaseClient client;
  const RecurringBlocksSupabaseRepo(this.client);

  Future<List<RecurringBlock>> fetchAll() async {
    final data = await client
        .from('recurring_blocks')
        .select()
        .order('start_minutes', ascending: true);

    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(RecurringBlock.fromSupabase).toList();
  }

  Future<void> create(RecurringBlock b) async {
    await client.from('recurring_blocks').insert(b.toSupabase());
  }

  Future<void> deleteById(String id) async {
    await client.from('recurring_blocks').delete().eq('id', id);
  }

  Future<void> setActive(String id, bool active) async {
    await client.from('recurring_blocks').update({'active': active}).eq('id', id);
  }
}