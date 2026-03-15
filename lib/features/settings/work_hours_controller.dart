import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/work_hours.dart';
import '../../storage/work_hours_repo_provider.dart';

class WorkHoursController extends Notifier<WorkHours> {
  @override
  WorkHours build() {
    final repo = ref.read(workHoursRepoProvider);
    return repo.load();
  }

  Future<bool> setHours({required int openHour, required int closeHour}) async {
    if (closeHour <= openHour) return false;

    final repo = ref.read(workHoursRepoProvider);
    final updated = WorkHours(openHour: openHour, closeHour: closeHour);
    state = updated;
    await repo.save(updated);
    return true;
  }
}

final workHoursProvider =
    NotifierProvider<WorkHoursController, WorkHours>(WorkHoursController.new);