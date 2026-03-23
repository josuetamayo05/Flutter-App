import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../storage/auth_token_repo_provider.dart';
import '../../api/auth_api_provider.dart';

class AuthController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final repo = ref.read(authTokenRepoProvider);
    return repo.load();
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authApiProvider);
      final repo = ref.read(authTokenRepoProvider);
      final token = await api.register(email, password);
      await repo.save(token);
      return token;
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authApiProvider);
      final repo = ref.read(authTokenRepoProvider);
      final token = await api.login(email, password);
      await repo.save(token);
      return token;
    });
  }

  Future<void> logout() async {
    final repo = ref.read(authTokenRepoProvider);
    await repo.clear();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthController, String?>(
  AuthController.new,
);