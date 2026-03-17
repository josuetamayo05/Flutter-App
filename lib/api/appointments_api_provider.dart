import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_provider.dart';
import 'appointments_api.dart';

final appointmentsApiProvider = Provider<AppointmentsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AppointmentsApi(dio);
});