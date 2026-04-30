import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/appointment.dart';
import '../../storage/appointments_local_repo_provider.dart';
import '../../utils/overlaps.dart';
import '../blocks/time_blocks_controller.dart';
import '../blocks/recurring_blocks_supabase_repo_provider.dart';
import 'appointments_supabase_repo_provider.dart';

class AppointmentsController extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final local = ref.read(appointmentsLocalRepoProvider);
    final repo = ref.read(appointmentsSupabaseRepoProvider);

    try {
      final remote = await repo.fetchAll();
      await local.save(remote);
      return remote;
    } catch (_) {
      // fallback offline
      return local.load();
    }
  }

  Future<bool> add(Appointment a) async {
    final localRepo = ref.read(appointmentsLocalRepoProvider);
    final repo = ref.read(appointmentsSupabaseRepoProvider);

    final current = state.value ?? [];

    final aStart = a.dateTime;
    final aEnd = a.endDateTime;

    // 1) Conflicto con turnos (local state)
    final hasApptConflict = current.any((b) {
      return overlaps(aStart, aEnd, b.dateTime, b.endDateTime);
    });
    if (hasApptConflict) return false;

    // 2) Conflicto con bloqueos puntuales (provider async)
    final blocks = await ref.read(timeBlocksProvider.future);
    final hasBlockConflict = blocks.any((b) {
      return overlaps(aStart, aEnd, b.start, b.end);
    });
    if (hasBlockConflict) return false;

    // 3) Conflicto con recurrentes (traemos de Supabase para estar seguros)
    final recurringRepo = ref.read(recurringBlocksSupabaseRepoProvider);
    final recurring = await recurringRepo.fetchAll();
    final hasRecurringConflict = recurring.any((r) {
      if (!r.active) return false;
      if (!r.weekdays.contains(aStart.weekday)) return false;

      final day = DateTime(aStart.year, aStart.month, aStart.day);
      final rStart = day.add(Duration(minutes: r.startMinutes));
      final rEnd = rStart.add(Duration(minutes: r.durationMinutes));
      return overlaps(aStart, aEnd, rStart, rEnd);
    });
    if (hasRecurringConflict) return false;

    // optimistic update
    final previous = current;
    final updated = [...current, a]..sort((x, y) => x.dateTime.compareTo(y.dateTime));

    state = AsyncData(updated);
    await localRepo.save(updated);

    try {
      await repo.create(a); // <-- Supabase insert
      return true;
    } catch (e) {
      // rollback
      state = AsyncData(previous);
      await localRepo.save(previous);
      rethrow;
    }
  }

  Future<void> removeById(String id) async {
    final localRepo = ref.read(appointmentsLocalRepoProvider);
    final repo = ref.read(appointmentsSupabaseRepoProvider);

    final current = state.value ?? [];
    final previous = current;
    final updated = current.where((x) => x.id != id).toList();

    state = AsyncData(updated);
    await localRepo.save(updated);

    try {
      await repo.deleteById(id);
    } catch (_) {
      state = AsyncData(previous);
      await localRepo.save(previous);
      rethrow;
    }
  }
}

final appointmentsProvider =
    AsyncNotifierProvider<AppointmentsController, List<Appointment>>(
  AppointmentsController.new,
);