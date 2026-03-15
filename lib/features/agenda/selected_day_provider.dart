import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/dates.dart';

final selectedDayProvider = StateProvider<DateTime>((ref) {
  return dateOnly(DateTime.now());
});