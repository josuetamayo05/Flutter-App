import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_block.dart';

class RecurringBlocksLocalRepo {
  static const _key = 'recurring_blocks_v1';
  final SharedPreferences prefs;

  RecurringBlocksLocalRepo(this.prefs);

  List<RecurringBlock> load() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => RecurringBlock.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<RecurringBlock> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
