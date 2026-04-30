import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/time_block.dart';

class TimeBlocksSupabaseRepo {
  final SupabaseClient client;
  const TimeBlocksSupabaseRepo(this.client);

  Future<List<TimeBlock>> fetchAll() async {
    final data = await client
        .from('time_blocks')
        .select()
        .order('starts_at', ascending: true);

    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(TimeBlock.fromSupabase).toList();
  }

  Future<TimeBlock> create({
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    final id = const Uuid().v4();

    final row = await client
        .from('time_blocks')
        .insert({
          'id': id,
          'title': title,
          'starts_at': start.toIso8601String(),
          'ends_at': end.toIso8601String(),
        })
        .select()
        .single();

    return TimeBlock.fromSupabase(row as Map<String, dynamic>);
  }

  Future<void> deleteById(String id) async {
    await client.from('time_blocks').delete().eq('id', id);
  }
}