import 'package:flutter/material.dart';

class EventType {
  final String id;
  final String name;
  final int durationMinutes;
  final String colorHex; // "#RRGGBB"
  final int? priceCents;
  final bool active;
  final int sortOrder;

  const EventType({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.colorHex,
    required this.priceCents,
    required this.active,
    required this.sortOrder,
  });

  Color get color {
    var hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'name': name,
        'duration_minutes': durationMinutes,
        'color_hex': colorHex,
        'price_cents': priceCents,
        'active': active,
        'sort_order': sortOrder,
      };

  factory EventType.fromSupabase(Map<String, dynamic> row) => EventType(
        id: row['id'] as String,
        name: row['name'] as String,
        durationMinutes: row['duration_minutes'] as int,
        colorHex: row['color_hex'] as String,
        priceCents: row['price_cents'] as int?,
        active: row['active'] as bool,
        sortOrder: (row['sort_order'] as num).toInt(),
      );
  EventType copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    String? colorHex,
    int? priceCents,
    bool? active,
    int? sortOrder,
  }) {
    return EventType(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      colorHex: colorHex ?? this.colorHex,
      priceCents: priceCents ?? this.priceCents,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}