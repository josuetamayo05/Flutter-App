import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_prefs_provider.dart';
import 'work_hours_repo.dart';

final workHoursRepoProvider = Provider<WorkHoursRepo>((ref) {
  final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
  return WorkHoursRepo(prefs);
});