import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_provider.dart';
import 'recurring_blocks_api.dart';

final recurringBlocksApiProvider = Provider<RecurringBlocksApi>((ref) {
  final dio = ref.watch(dioProvider);
  return RecurringBlocksApi(dio);
});