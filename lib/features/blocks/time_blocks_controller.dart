import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/time_block.dart';
import 'time_blocks_supabase_repo_provider.dart';

class TimeBlocksController extends AsyncNotifier<List<TimeBlock>> {
  @override
  Future<List<TimeBlock>> build() async {
    final repo = ref.read(timeBlocksSupabaseRepoProvider);
    return repo.fetchAll();
  }

  Future<void> addBlock({
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    final repo = ref.read(timeBlocksSupabaseRepoProvider);
    await repo.create(title: title, start: start, end: end);
    state = AsyncData(await repo.fetchAll());
  }
  
  Future<void> add(TimeBlock b) async {
    await addBlock(title: b.title, start: b.start, end: b.end);
  }

  Future<void> removeById(String id) async {
    final repo = ref.read(timeBlocksSupabaseRepoProvider);
    await repo.deleteById(id);
    state = AsyncData(await repo.fetchAll());
  }
}

final timeBlocksProvider =
    AsyncNotifierProvider<TimeBlocksController, List<TimeBlock>>(
  TimeBlocksController.new,
);