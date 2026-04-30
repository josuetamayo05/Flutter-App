import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supabase/supabase_client_provider.dart';
import 'appointments_supabase_repo.dart';

final appointmentsSupabaseRepoProvider = Provider<AppointmentsSupabaseRepo>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AppointmentsSupabaseRepo(client);
});