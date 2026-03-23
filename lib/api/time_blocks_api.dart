import 'package:dio/dio.dart';
import '../models/time_block.dart';

class TimeBlocksApi {
  final Dio dio;
  TimeBlocksApi(this.dio);

  Future<List<TimeBlock>> fetchAll() async {
    final res = await dio.get('/time-blocks');
    final data = (res.data as List).cast<Map<String, dynamic>>();
    return data.map(TimeBlock.fromJson).toList();
  }

  Future<void> create(TimeBlock b) async {
    await dio.post('/time-blocks', data: b.toJson());
  }

  Future<void> deleteById(String id) async {
    await dio.delete('/time-blocks/$id');
  }
}