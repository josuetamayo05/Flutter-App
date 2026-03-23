import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_provider.dart';
import 'time_blocks_api.dart';

final timeBlocksApiProvider = Provider<TimeBlocksApi>((ref) {
  final dio = ref.watch(dioProvider);
  return TimeBlocksApi(dio);
});