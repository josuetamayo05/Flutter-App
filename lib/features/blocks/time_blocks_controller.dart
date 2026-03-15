import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/time_block.dart';
import '../../storage/time_blocks_local_repo_provider.dart';

class TimeBlocksController extends AsyncNotifier<List<TimeBlock>> {
  @override
  Future<List<TimeBlock>> build() async {
    final repo = ref.read(timeBlocksLocalRepoProvider);
    final items = repo.load()..sort((a, b) => a.start.compareTo(b.start));
    return items;
  }

  Future<void> add(TimeBlock b) async {
    final repo = ref.read(timeBlocksLocalRepoProvider);
    final current = state.value ?? [];
    final updated = [...current, b]..sort((x, y) => x.start.compareTo(y.start));
    state = AsyncData(updated);
    await repo.save(updated);
  }

  Future<void> removeById(String id) async {
    final repo = ref.read(timeBlocksLocalRepoProvider);
    final current = state.value ?? [];
    final updated = current.where((x) => x.id != id).toList();
    state = AsyncData(updated);
    await repo.save(updated);
  }
}

final timeBlocksProvider =
    AsyncNotifierProvider<TimeBlocksController, List<TimeBlock>>(
  TimeBlocksController.new,
);