class TimeBlock {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;

  const TimeBlock({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  factory TimeBlock.fromJson(Map<String, dynamic> json) => TimeBlock(
        id: json['id'] as String,
        title: json['title'] as String,
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
      );
}