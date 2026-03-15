import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';
import 'appointments_local_repo.dart';

final appointmentsLocalRepoProvider = Provider<AppointmentsLocalRepo>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppointmentsLocalRepo(prefs);
});