import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_type.dart';
import '../../supabase/supabase_client_provider.dart';
import 'event_types_supabase_repo_provider.dart';

class EventTypesController extends AsyncNotifier<List<EventType>> {
  StreamSubscription<List<EventType>>? _sub;

  @override
  Future<List<EventType>> build() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final repo = ref.read(eventTypesSupabaseRepoProvider);

    final initial = await repo.fetchAll();

    _sub = repo.streamAll(userId).listen(
      (items) => state = AsyncData(items),
      onError: (e, st) => state = AsyncError(e, st),
    );

    ref.onDispose(() => _sub?.cancel());
    return initial;
  }

  Future<void> createEventType(EventType e) async {
    final repo = ref.read(eventTypesSupabaseRepoProvider);
    await repo.create(e);
  }


  Future<void> updateEventType(EventType e) async {
    final repo = ref.read(eventTypesSupabaseRepoProvider);
    await repo.update(e);
  }

  Future<void> deleteEventType(String id) async {
    final repo = ref.read(eventTypesSupabaseRepoProvider);
    await repo.deleteById(id);
  }

  Future<void> setEventTypeActive(String id, bool active) async {
    final repo = ref.read(eventTypesSupabaseRepoProvider);
    await repo.setActive(id, active);
  }
}

final eventTypesProvider =
    AsyncNotifierProvider<EventTypesController, List<EventType>>(
  EventTypesController.new,
);