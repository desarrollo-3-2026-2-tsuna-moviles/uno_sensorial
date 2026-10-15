import 'package:vector_math/vector_math_64.dart' as vmath;
import 'card_model.dart';

/// Modelo de Jugador en la arquitectura MVVM
class PlayerModel {
  final String id;
  final String name;
  final int seatIndex;
  final List<UnoCard> cards;
  vmath.Quaternion rotation;

  PlayerModel({
    required this.id,
    required this.name,
    required this.seatIndex,
    List<UnoCard>? cards,
    vmath.Quaternion? rotation,
  })  : cards = cards ?? <UnoCard>[],
        rotation = rotation ?? vmath.Quaternion.identity();

  int get cardCount => cards.length;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'seatIndex': seatIndex,
        'cardCount': cards.length,
      };

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      seatIndex: json['seatIndex'] as int,
    );
  }
}
