import 'package:flutter/material.dart';

/// Colores estándar de las cartas UNO
enum UnoColor { red, blue, green, yellow, wild }

/// Tipos de cartas UNO
enum UnoType { number, skip, reverse, drawTwo, wild, wildDrawFour }

/// Modelo de Carta UNO
class UnoCard {
  final String id;
  final UnoColor color;
  final UnoType type;
  final int? number; // 0-9 para cartas numéricas

  const UnoCard({
    required this.id,
    required this.color,
    required this.type,
    this.number,
  });

  Color get displayColor {
    switch (color) {
      case UnoColor.red:
        return const Color(0xFFD32F2F);
      case UnoColor.blue:
        return const Color(0xFF0055B8);
      case UnoColor.green:
        return const Color(0xFF2E7D32);
      case UnoColor.yellow:
        return const Color(0xFFFBC02D);
      case UnoColor.wild:
        return Colors.black;
    }
  }

  String get displayLabel {
    switch (type) {
      case UnoType.number:
        return '${number ?? 0}';
      case UnoType.skip:
        return '🚫';
      case UnoType.reverse:
        return '🔄';
      case UnoType.drawTwo:
        return '+2';
      case UnoType.wild:
        return '★';
      case UnoType.wildDrawFour:
        return '+4';
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'color': color.name,
        'type': type.name,
        'number': number,
      };

  factory UnoCard.fromJson(Map<String, dynamic> json) {
    return UnoCard(
      id: json['id'] as String,
      color: UnoColor.values.firstWhere((UnoColor c) => c.name == json['color']),
      type: UnoType.values.firstWhere((UnoType t) => t.name == json['type']),
      number: json['number'] as int?,
    );
  }
}
