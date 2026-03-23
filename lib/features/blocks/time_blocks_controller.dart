import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/time_blocks_api_provider.dart';
import '../../models/time_block.dart';
import '../../storage/time_blocks_local_repo_provider.dart';

class TimeBlocksController extends AsyncNotifier<List<TimeBlock>> {
  @override
  Future<List<TimeBlock>> build() async {
    final local = ref.read(timeBlocksLocalRepoProvider);
    final cached = local.load()..sort((a, b) => a.start.compareTo(b.start));
    final api = ref.read(timeBlocksApiProvider);

    try {
      final remote = await api.fetchAll();
      await local.save(remote);
      return remote;
    } catch (_) {
      return local.load();
    }
  }

  Future<void> add(TimeBlock b) async {
    final local = ref.read(timeBlocksLocalRepoProvider);
    final api = ref.read(timeBlocksApiProvider);

    final previous = state.value ?? [];
    final updated = [...previous, b]..sort((a, b) => a.start.compareTo(b.start));

    // Optimistic
    state = AsyncData(updated);
    await local.save(updated);

    try {
      await api.create(b);
    } catch (e) {
      // Rollback
      state = AsyncData(previous);
      await local.save(previous);
      rethrow;
    }
  }

  Future<void> removeById(String id) async {
    final local = ref.read(timeBlocksLocalRepoProvider);
    final api = ref.read(timeBlocksApiProvider);

    final previous = state.value ?? [];
    final updated = previous.where((x) => x.id != id).toList();

    // Optimistic
    state = AsyncData(updated);
    await local.save(updated);

    try {
      await api.deleteById(id);
    } catch (e) {
      // Rollback
      state = AsyncData(previous);
      await local.save(previous);
      rethrow;
    }
  }
}

final timeBlocksProvider =
    AsyncNotifierProvider<TimeBlocksController, List<TimeBlock>>(
  TimeBlocksController.new,
);