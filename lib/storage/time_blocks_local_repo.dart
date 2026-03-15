import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_block.dart';

class TimeBlocksLocalRepo {
  static const _key = 'time_blocks_v1';
  final SharedPreferences prefs;

  TimeBlocksLocalRepo(this.prefs);

  List<TimeBlock> load() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => TimeBlock.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<TimeBlock> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}