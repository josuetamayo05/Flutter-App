class WorkHours {
  final int openHour;  // 0..23
  final int closeHour; // 0..23, debe ser > openHour

  const WorkHours({
    required this.openHour,
    required this.closeHour,
  });

  WorkHours copyWith({int? openHour, int? closeHour}) => WorkHours(
        openHour: openHour ?? this.openHour,
        closeHour: closeHour ?? this.closeHour,
      );
}