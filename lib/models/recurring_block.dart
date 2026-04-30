class RecurringBlock {
  final String id;
  final String title;

  /// DateTime.weekday: 1=Lun ... 7=Dom
  final List<int> weekdays;

  /// minutos desde medianoche (ej 12:30 => 750)
  final int startMinutes;

  final int durationMinutes;
  final bool active;

  const RecurringBlock({
    required this.id,
    required this.title,
    required this.weekdays,
    required this.startMinutes,
    required this.durationMinutes,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'weekdays': weekdays,
    'startMinutes': startMinutes,
    'durationMinutes': durationMinutes,
    'active': active,
  };

  factory RecurringBlock.fromJson(Map<String, dynamic> json) => RecurringBlock(
    id: json['id'] as String,
    title: json['title'] as String,
    weekdays: (json['weekdays'] as List).cast<int>(),
    startMinutes: json['startMinutes'] as int,
    durationMinutes: json['durationMinutes'] as int,
    active: (json['active'] as bool?) ?? true,
  );

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'title': title,
    'weekdays': weekdays,
    'start_minutes': startMinutes,
    'duration_minutes': durationMinutes,
    'active': active,
  };

  factory RecurringBlock.fromSupabase(Map<String, dynamic> row) => RecurringBlock(
    id: row['id'] as String,
    title: row['title'] as String,
    weekdays: (row['weekdays'] as List).map((e) => e as int).toList(),
    startMinutes: row['start_minutes'] as int,
    durationMinutes: row['duration_minutes'] as int,
    active: row['active'] as bool,
  );
}
