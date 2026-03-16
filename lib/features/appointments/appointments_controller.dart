import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment.dart';
import '../../storage/appointments_local_repo_provider.dart';
import '../../utils/overlaps.dart';
import '../blocks/time_blocks_controller.dart';
import '../blocks/recurring_blocks_controller.dart';

class AppointmentsController extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final repo = ref.read(appointmentsLocalRepoProvider);
    return repo.load();
  }

  Future<bool> add(Appointment a) async {
    final repo = ref.read(appointmentsLocalRepoProvider);
    final current = state.value ?? [];

    final aStart = a.dateTime;
    final aEnd = a.endDateTime;

    // 1) Conflicto con otros turnos
    final hasApptConflict = current.any((b) {
      return overlaps(aStart, aEnd, b.dateTime, b.endDateTime);
    });
    if (hasApptConflict) return false;

    // 2) Conflicto con bloqueos (aseguramos que estén cargados)
    final blocks = await ref.read(timeBlocksProvider.future);
    final hasBlockConflict = blocks.any((b) {
      return overlaps(aStart, aEnd, b.start, b.end);
    });
    if (hasBlockConflict) return false;

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

    final updated = [...current, a]..sort((x, y) => x.dateTime.compareTo(y.dateTime));
    state = AsyncData(updated);
    await repo.save(updated);
    return true;
  }

  Future<void> removeById(String id) async {
    final repo = ref.read(appointmentsLocalRepoProvider);
    final current = state.value ?? [];
    final updated = current.where((x) => x.id != id).toList();
    state = AsyncData(updated);
    await repo.save(updated);
  }
}

final appointmentsProvider =
    AsyncNotifierProvider<AppointmentsController, List<Appointment>>(
      AppointmentsController.new,
    );
