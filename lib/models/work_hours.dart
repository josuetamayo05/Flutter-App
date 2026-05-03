class WorkHours {
  final int openHour;  // 0..23
  final int closeHour; // 0..23
  final int slotStepMinutes; // 5,10,15,20,30,60

  const WorkHours({
    required this.openHour,
    required this.closeHour,
    required this.slotStepMinutes,
  });

  WorkHours copyWith({int? openHour, int? closeHour, int? slotStepMinutes}) => WorkHours(
        openHour: openHour ?? this.openHour,
        closeHour: closeHour ?? this.closeHour,
        slotStepMinutes: slotStepMinutes ?? this.slotStepMinutes,
      );

  static const defaults = WorkHours(openHour: 9, closeHour: 18, slotStepMinutes: 30);

  factory WorkHours.fromSupabase(Map<String, dynamic> row) => WorkHours(
        openHour: row['open_hour'] as int,
        closeHour: row['close_hour'] as int,
        slotStepMinutes: (row['slot_step_minutes'] as num?)?.toInt() ?? 30,
      );

  Map<String, dynamic> toSupabase() => {
        'open_hour': openHour,
        'close_hour': closeHour,
        'slot_step_minutes': slotStepMinutes,
      };
}