import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/time_block.dart';
import 'time_blocks_supabase_repo_provider.dart';
import 'dart:async';
import '../../supabase/supabase_client_provider.dart';
import '../../storage/time_blocks_local_repo_provider.dart';

class TimeBlocksController extends AsyncNotifier<List<TimeBlock>> {
  StreamSubscription<List<TimeBlock>>? _sub;

  @override
  Future<List<TimeBlock>> build() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;

    final local = ref.read(timeBlocksLocalRepoProvider);
    final repo = ref.read(timeBlocksSupabaseRepoProvider);

    if (userId == null) return [];

    List<TimeBlock> initial;
    try {
      initial = await repo.fetchAll();
      await local.save(initial);
    } catch (_) {
      initial = local.load();
    }

    _sub = repo.streamAll(userId).listen((items) async {
      state = AsyncData(items);
      await local.save(items);
    }, onError: (e, st) {
      state = AsyncError(e, st);
    });

    ref.onDispose(() => _sub?.cancel());

    return initial;
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