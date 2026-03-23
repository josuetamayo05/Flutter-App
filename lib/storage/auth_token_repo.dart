import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenRepo {
  static const _key = 'auth_token_v1';
  final SharedPreferences prefs;
  AuthTokenRepo(this.prefs);

  String? load() => prefs.getString(_key);

  Future<void> save(String token) => prefs.setString(_key, token);

  Future<void> clear() => prefs.remove(_key);
}