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
}
