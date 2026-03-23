import 'package:dio/dio.dart';
import '../models/recurring_block.dart';

class RecurringBlocksApi {
  final Dio dio;
  RecurringBlocksApi(this.dio);

  Future<List<RecurringBlock>> fetchAll() async {
    final res = await dio.get('/recurring-blocks');
    final data = (res.data as List).cast<Map<String, dynamic>>();
    return data.map(RecurringBlock.fromJson).toList();
  }

  Future<void> create(RecurringBlock b) async {
    await dio.post('/recurring-blocks', data: b.toJson());
  }

  Future<void> deleteById(String id) async {
    await dio.delete('/recurring-blocks/$id');
  }

  Future<void> setActive(String id, bool active) async {
    await dio.patch('/recurring-blocks/$id', data: {'active': active});
  }
}