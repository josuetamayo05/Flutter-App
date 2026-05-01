import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/recurring_block.dart';
import '../../storage/recurring_blocks_local_repo_provider.dart';
import 'recurring_blocks_supabase_repo_provider.dart';
import 'dart:async';
import '../../supabase/supabase_client_provider.dart';

class RecurringBlocksController extends Notifier<List<RecurringBlock>> {
  @override
  StreamSubscription<List<RecurringBlock>>? _sub;

  @override
  List<RecurringBlock> build() {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;

    final local = ref.read(recurringBlocksLocalRepoProvider);
    final repo = ref.read(recurringBlocksSupabaseRepoProvider);

    final cached = local.load()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    if (userId != null) {
      _sub = repo.streamAll(userId).listen((items) async {
        state = items;
        await local.save(items);
      });

      ref.onDispose(() => _sub?.cancel());
    }

    return cached;
  }

  Future<void> add(RecurringBlock b) async {
    final local = ref.read(recurringBlocksLocalRepoProvider);
    final repo = ref.read(recurringBlocksSupabaseRepoProvider);

    final previous = state;
    final updated = [...state, b]..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    state = updated;
    await local.save(updated);

    try {
      await repo.create(b);
    } catch (e) {
      state = previous;
      await local.save(previous);
      rethrow;
    }
  }

  Future<void> removeById(String id) async {
    final local = ref.read(recurringBlocksLocalRepoProvider);
    final repo = ref.read(recurringBlocksSupabaseRepoProvider);

    final previous = state;
    final updated = state.where((x) => x.id != id).toList();

    state = updated;
    await local.save(updated);

    try {
      await repo.deleteById(id);
    } catch (e) {
      state = previous;
      await local.save(previous);
      rethrow;
    }
  }

  Future<void> toggle(String id, bool active) async {
    final local = ref.read(recurringBlocksLocalRepoProvider);
    final repo = ref.read(recurringBlocksSupabaseRepoProvider);

    final previous = state;
    final updated = [
      for (final x in state)
        if (x.id == id)
          RecurringBlock(
            id: x.id,
            title: x.title,
            weekdays: x.weekdays,
            startMinutes: x.startMinutes,
            durationMinutes: x.durationMinutes,
            active: active,
          )
        else
          x
    ];

    state = updated;
    await local.save(updated);

    try {
      await repo.setActive(id, active);
    } catch (e) {
      state = previous;
      await local.save(previous);
      rethrow;
    }
  }
}

final recurringBlocksProvider =
    NotifierProvider<RecurringBlocksController, List<RecurringBlock>>(
  RecurringBlocksController.new,
);