import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment.dart';
import '../../storage/appointments_local_repo_provider.dart';
import '../../utils/overlaps.dart';
import '../blocks/time_blocks_controller.dart';
import '../blocks/recurring_blocks_controller.dart';
import '../../api/appointments_api_provider.dart';

class AppointmentsController extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final local = ref.read(appointmentsLocalRepoProvider);
    final api = ref.read(appointmentsApiProvider);

    try {
      final remoteItems = await api.fetchAll();
      await local.save(remoteItems);
      return remoteItems;
    } catch (_) {
      // si falla internet/servidor, usamos cache local
      return local.load();
    }
  }

  Future<bool> add(Appointment a) async {
    final localRepo = ref.read(appointmentsLocalRepoProvider);
    final api = ref.read(appointmentsApiProvider);

    final current = state.value ?? [];

    final aStart = a.dateTime;
    final aEnd = a.endDateTime;

    // 1) Conflicto con turnos
    final hasApptConflict = current.any((b) {
      return overlaps(aStart, aEnd, b.dateTime, b.endDateTime);
    });
    if (hasApptConflict) return false;

    // 2) Conflicto con bloqueos puntuales
    final blocks = await ref.read(timeBlocksProvider.future);
    final hasBlockConflict = blocks.any((b) {
      return overlaps(aStart, aEnd, b.start, b.end);
    });
    if (hasBlockConflict) return false;

    // 3) Conflicto con recurrentes
    final recurring = ref.read(recurringBlocksProvider);
    final hasRecurringConflict = recurring.any((r) {
      if (!r.active) return false;
      if (!r.weekdays.contains(aStart.weekday)) return false;

      final day = DateTime(aStart.year, aStart.month, aStart.day);
      final rStart = day.add(Duration(minutes: r.startMinutes));
      final rEnd = rStart.add(Duration(minutes: r.durationMinutes));
      return overlaps(aStart, aEnd, rStart, rEnd);
    });
    if (hasRecurringConflict) return false;

    // --- Optimistic update + rollback si falla backend ---
    final previous = current;
    final updated = [...current, a]..sort((x, y) => x.dateTime.compareTo(y.dateTime));

    state = AsyncData(updated);
    await localRepo.save(updated);

    try {
      await api.create(a);
      return true;
    } catch (e) {
      state = AsyncData(previous);
      await localRepo.save(previous);
      rethrow; // para que la UI muestre un mensaje
    }
  }

  Future<void> removeById(String id) async {
    final localRepo = ref.read(appointmentsLocalRepoProvider);
    final api = ref.read(appointmentsApiProvider);

    final current = state.value ?? [];
    final previous = current;
    final updated = current.where((x) => x.id != id).toList();

    state = AsyncData(updated);
    await localRepo.save(updated);

    try {
      await api.deleteById(id);
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
