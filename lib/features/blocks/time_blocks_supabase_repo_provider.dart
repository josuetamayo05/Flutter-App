import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supabase/supabase_client_provider.dart';
import 'time_blocks_supabase_repo.dart';

final timeBlocksSupabaseRepoProvider = Provider<TimeBlocksSupabaseRepo>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TimeBlocksSupabaseRepo(client);
});