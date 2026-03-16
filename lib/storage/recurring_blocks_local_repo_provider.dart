import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';
import 'recurring_blocks_local_repo.dart';

final recurringBlocksLocalRepoProvider = Provider<RecurringBlocksLocalRepo>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RecurringBlocksLocalRepo(prefs);
});