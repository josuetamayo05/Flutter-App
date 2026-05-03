import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supabase/supabase_client_provider.dart';
import 'work_hours_supabase_repo.dart';

final workHoursSupabaseRepoProvider = Provider<WorkHoursSupabaseRepo>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WorkHoursSupabaseRepo(client);
});