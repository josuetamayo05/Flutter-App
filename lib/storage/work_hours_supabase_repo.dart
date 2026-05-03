import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/work_hours.dart';

class WorkHoursSupabaseRepo {
  final SupabaseClient client;
  WorkHoursSupabaseRepo(this.client);

  Future<WorkHours> fetchOrCreate(String userId) async {
    final row = await client
        .from('work_hours')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) {
      final inserted = await client
          .from('work_hours')
          .insert({
            'user_id': userId,
            ...WorkHours.defaults.toSupabase(),
          })
          .select()
          .single();

      return WorkHours.fromSupabase(inserted);
    }

    return WorkHours.fromSupabase(row);
  }

  Stream<WorkHours> streamOne(String userId) {
    return client
        .from('work_hours')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) return WorkHours.defaults;
          return WorkHours.fromSupabase(rows.first);
        });
  }

  Future<void> upsert(String userId, WorkHours hours) async {
    await client.from('work_hours').upsert({
      'user_id': userId,
      ...hours.toSupabase(),
    });
  }
}