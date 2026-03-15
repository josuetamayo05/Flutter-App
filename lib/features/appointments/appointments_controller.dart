import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment.dart';

class AppointmentsController extends Notifier<List<Appointment>> {
  @override
  List<Appointment> build() => [];

  void add(Appointment a) {
    state = [...state, a];
  }

  void removeById(String id) {
    state = state.where((x) => x.id != id).toList();
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsController, List<Appointment>>(
  AppointmentsController.new,
);
