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
      
  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.parse(v as String);
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'title': title,
        'starts_at': start.toIso8601String(),
        'ends_at': end.toIso8601String(),
      };

  factory TimeBlock.fromSupabase(Map<String, dynamic> row) => TimeBlock(
        id: row['id'] as String,
        title: row['title'] as String,
        start: _parseDate(row['starts_at']),
        end: _parseDate(row['ends_at']),
      );
}