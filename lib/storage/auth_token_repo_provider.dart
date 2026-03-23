import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_token_repo.dart';
import 'shared_prefs_provider.dart';

final authTokenRepoProvider = Provider<AuthTokenRepo>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthTokenRepo(prefs);
});