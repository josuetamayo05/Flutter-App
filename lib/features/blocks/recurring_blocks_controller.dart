import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/recurring_block.dart';
import '../../../storage/recurring_blocks_local_repo_provider.dart';

class RecurringBlocksController extends Notifier<List<RecurringBlock>> {
  @override
  List<RecurringBlock> build() {
    final repo = ref.read(recurringBlocksLocalRepoProvider);
    final items = repo.load();
    items.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return items;
  }

  Future<void> add(RecurringBlock b) async {
    final repo = ref.read(recurringBlocksLocalRepoProvider);
    final updated = [...state, b]..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    state = updated;
    await repo.save(updated);
  }

  Future<void> removeById(String id) async {
    final repo = ref.read(recurringBlocksLocalRepoProvider);
    final updated = state.where((x) => x.id != id).toList();
    state = updated;
    await repo.save(updated);
  }

  Future<void> toggle(String id, bool active) async {
    final repo = ref.read(recurringBlocksLocalRepoProvider);
    final updated = [
      for (final x in state)
        if (x.id == id) RecurringBlock(
          id: x.id,
          title: x.title,
          weekdays: x.weekdays,
          startMinutes: x.startMinutes,
          durationMinutes: x.durationMinutes,
          active: active,
        ) else x
    ];
    state = updated;
    await repo.save(updated);
  }
}

final recurringBlocksProvider =
    NotifierProvider<RecurringBlocksController, List<RecurringBlock>>(
  RecurringBlocksController.new,
);