import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/work_hours.dart';
import '../../supabase/supabase_client_provider.dart';
import '../../storage/work_hours_supabase_repo_provider.dart';

class WorkHoursController extends AsyncNotifier<WorkHours> {
  StreamSubscription<WorkHours>? _sub;

  @override
  Future<WorkHours> build() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return WorkHours.defaults;

    final repo = ref.read(workHoursSupabaseRepoProvider);
    final initial = await repo.fetchOrCreate(userId);

    _sub = repo
        .streamOne(userId)
        .listen(
          (h) => state = AsyncData(h),
          onError: (e, st) => state = AsyncError(e, st),
        );

    ref.onDispose(() => _sub?.cancel());
    return initial;
  }

  Future<bool> setHours({required int openHour, required int closeHour}) async {
    if (closeHour <= openHour) return false;

    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    final current = state.value ?? WorkHours.defaults;
    final updated = current.copyWith(openHour: openHour, closeHour: closeHour);

    state = AsyncData(updated);
    final repo = ref.read(workHoursSupabaseRepoProvider);
    await repo.upsert(userId, updated);
    return true;
  }

  Future<bool> setSlotStepMinutes(int minutes) async {
    const allowed = {5, 10, 15, 20, 30, 60};
    if (!allowed.contains(minutes)) return false;

    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    final current = state.value ?? WorkHours.defaults;
    final updated = current.copyWith(slotStepMinutes: minutes);

    state = AsyncData(updated);
    final repo = ref.read(workHoursSupabaseRepoProvider);
    await repo.upsert(userId, updated);
    return true;
  }
}

final workHoursProvider = AsyncNotifierProvider<WorkHoursController, WorkHours>(
  WorkHoursController.new,
);
