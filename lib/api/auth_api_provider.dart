import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_api.dart';
import 'public_dio_provider.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(publicDioProvider);
  return AuthApi(dio);
});