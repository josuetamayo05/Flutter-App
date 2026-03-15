import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';

class AppointmentsLocalRepo {
  static const _key = 'appointments_v2';
  final SharedPreferences prefs;

  AppointmentsLocalRepo(this.prefs);

  List<Appointment> load() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Appointment> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}