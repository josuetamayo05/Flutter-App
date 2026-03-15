import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment.dart';
import '../../storage/appointments_local_repo_provider.dart';

class AppointmentsController extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final repo = ref.read(appointmentsLocalRepoProvider);
    return repo.load();
  }

  bool _overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  Future<bool> add(Appointment a) async {
    final repo = ref.read(appointmentsLocalRepoProvider);
    final current = state.value ?? [];

    final aStart = a.dateTime;
    final aEnd = a.endDateTime;

    bool hasConflict = current.any((b) {
      final bStart = b.dateTime;
      final bEnd = b.endDateTime;
      return _overlaps(aStart, aEnd, bStart, bEnd);
    });

    if (hasConflict) return false;

    final updated = [...current, a]
      ..sort((x, y) => x.dateTime.compareTo(y.dateTime));

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
