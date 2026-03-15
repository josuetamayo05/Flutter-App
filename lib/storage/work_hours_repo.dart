import 'package:shared_preferences/shared_preferences.dart';
import '../models/work_hours.dart';

class WorkHoursRepo {
  static const _openKey = 'work_hours_open_v1';
  static const _closeKey = 'work_hours_close_v1';

  final SharedPreferences prefs;
  WorkHoursRepo(this.prefs);

  WorkHours load() {
    final open = prefs.getInt(_openKey) ?? 9;
    final close = prefs.getInt(_closeKey) ?? 18;
    return WorkHours(openHour: open, closeHour: close);
  }

  Future<void> save(WorkHours hours) async {
    await prefs.setInt(_openKey, hours.openHour);
    await prefs.setInt(_closeKey, hours.closeHour);
  }
}