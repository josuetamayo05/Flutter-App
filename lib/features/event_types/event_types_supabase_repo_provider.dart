import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supabase/supabase_client_provider.dart';
import 'event_types_supabase_repo.dart';

final eventTypesSupabaseRepoProvider = Provider<EventTypesSupabaseRepo>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EventTypesSupabaseRepo(client);
});