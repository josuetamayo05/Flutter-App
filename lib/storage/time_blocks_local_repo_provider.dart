import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';
import 'time_blocks_local_repo.dart';

final timeBlocksLocalRepoProvider = Provider<TimeBlocksLocalRepo>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TimeBlocksLocalRepo(prefs);
});