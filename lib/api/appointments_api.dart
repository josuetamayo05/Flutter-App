import 'package:dio/dio.dart';
import '../../models/appointment.dart';

class AppointmentsApi {
  final Dio dio;
  AppointmentsApi(this.dio);

  Future<List<Appointment>> fetchAll() async {
    final res = await dio.get('/appointments');
    final data = (res.data as List).cast<Map<String, dynamic>>();
    return data.map(Appointment.fromJson).toList();
  }

  Future<void> create(Appointment a) async {
    await dio.post('/appointments', data: a.toJson());
  }

  Future<void> deleteById(String id) async {
    await dio.delete('/appointments/$id');
  }
}