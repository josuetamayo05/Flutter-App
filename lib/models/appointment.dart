class Appointment {
  final String id;
  final String clientName;
  final String serviceId;
  final int durationMinutes;
  final DateTime dateTime;

  const Appointment({
    required this.id,
    required this.clientName,
    required this.serviceId,
    required this.durationMinutes,
    required this.dateTime,
  });

  DateTime get endDateTime => dateTime.add(Duration(minutes: durationMinutes));
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'clientName': clientName,
    'service': serviceId,
    'durationMinutes': durationMinutes, 
    'dateTime': dateTime.toIso8601String(),
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    clientName: json['clientName'] as String,
    serviceId: json['service'] as String,
    durationMinutes: json['durationMinutes'] as int,
    dateTime: DateTime.parse(json['dateTime'] as String),
  );
}
