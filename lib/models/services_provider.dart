import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/service.dart';

final servicesProvider = Provider<List<Service>>((ref) {
  return const [
    Service(id: 'corte', name: 'Corte', durationMinutes: 30, price: 5),
    Service(id: 'barba', name: 'Barba', durationMinutes: 20, price: 3),
    Service(id: 'combo', name: 'Corte + Barba', durationMinutes: 45, price: 7),
  ];
});