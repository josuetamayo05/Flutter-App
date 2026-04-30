import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_client_provider.dart';

class AuthController extends AsyncNotifier<Session?> {
  StreamSubscription<AuthState>? _sub;

  @override
  FutureOr<Session?> build() {
    final client = ref.read(supabaseClientProvider);

    // Escuchar cambios de auth (login/logout/refresh)
    _sub = client.auth.onAuthStateChange.listen((data) {
      state = AsyncData(data.session);
    });

    ref.onDispose(() => _sub?.cancel());

    // Estado inicial
    return client.auth.currentSession;
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signUp(email: email, password: password);
      return client.auth.currentSession; // puede ser null si email confirm está ON
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(email: email, password: password);
      return client.auth.currentSession;
    });
  }

  Future<void> logout() async {
    final client = ref.read(supabaseClientProvider);
    await client.auth.signOut();
    state = const AsyncData(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthController, Session?>(AuthController.new);