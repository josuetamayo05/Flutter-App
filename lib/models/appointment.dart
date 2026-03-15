class Appointment {
  final String id;
  final String clientName;
  final String service;
  final DateTime dateTime;

  const Appointment({
    required this.id,
    required this.clientName,
    required this.service,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'service': service,
        'dateTime': dateTime.toIso8601String(),
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        clientName: json['clientName'] as String,
        service: json['service'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
      );
}
