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
    'serviceId': serviceId,
    'durationMinutes': durationMinutes, 
    'dateTime': dateTime.toIso8601String(),
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    clientName: json['clientName'] as String,
    serviceId: json['serviceId'] as String,
    durationMinutes: json['durationMinutes'] as int,
    dateTime: DateTime.parse(json['dateTime'] as String),
  );
    

    static DateTime _parseDate(dynamic v) {
      if (v is DateTime) return v;
      return DateTime.parse(v as String);
    }

    Map<String, dynamic> toSupabase() => {
          'id': id,
          'client_name': clientName,
          'service_id': serviceId,
          'duration_minutes': durationMinutes,
          'date_time': dateTime.toIso8601String(),
        };

    factory Appointment.fromSupabase(Map<String, dynamic> row) => Appointment(
          id: row['id'] as String,
          clientName: row['client_name'] as String,
          serviceId: row['service_id'] as String,
          durationMinutes: row['duration_minutes'] as int,
          dateTime: _parseDate(row['date_time']),
        );
  
}
