import 'package:dio/dio.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<String> register(String email, String password) async {
    final res = await dio.post('/auth/register', data: {
      'email': email,
      'password': password,
    });
    return res.data['accessToken'] as String;
  }

  Future<String> login(String email, String password) async {
    final res = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return res.data['accessToken'] as String;
  }
}