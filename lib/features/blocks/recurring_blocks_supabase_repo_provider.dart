import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supabase/supabase_client_provider.dart';
import 'recurring_blocks_supabase_repo.dart';

final recurringBlocksSupabaseRepoProvider = Provider<RecurringBlocksSupabaseRepo>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RecurringBlocksSupabaseRepo(client);
});