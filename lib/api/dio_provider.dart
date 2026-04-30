import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_controller.dart';
import 'api_base_url.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenAsync = ref.watch(authProvider);
  final token = tokenAsync.valueOrNull;

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token != null && token.isExpired) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          await ref.read(authProvider.notifier).logout();
        }
        handler.next(e);
      },
    ),
  );

  return dio;
});