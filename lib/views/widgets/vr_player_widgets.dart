import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/player_model.dart';
import 'carta_uno_widget.dart';

/// Placa de un rival: avatar, nombre y número de cartas.
class PlayerNameplate extends StatelessWidget {
  const PlayerNameplate({super.key, required this.player, required this.isCurrentTurn});

  static const Size size = Size(128, 64);

  final PlayerModel player;
  final bool isCurrentTurn;

  @override
  Widget build(BuildContext context) {
    final Color accent = isCurrentTurn ? Colors.amberAccent : Colors.white24;
    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: isCurrentTurn ? 2.5 : 1),
        boxShadow: isCurrentTurn
            ? const <BoxShadow>[BoxShadow(color: Color(0x80FFD60A), blurRadius: 14, spreadRadius: 2)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 12,
                backgroundColor: isCurrentTurn ? Colors.amberAccent : Colors.blueAccent,
                child: Text(
                  player.name.isEmpty ? '?' : player.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(color: Colors.amberAccent, borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${player.cardCount} cartas',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// Abanico de cartas boca abajo que un rival sostiene frente a sí.
class OpponentHandFan extends StatelessWidget {
  const OpponentHandFan({super.key, required this.cardCount});

  static const Size size = Size(130, 92);
  static const int maxVisible = 7;

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final int count = min(cardCount, maxVisible);
    return SizedBox.fromSize(
      size: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          for (int i = 0; i < count; i++)
            Transform.rotate(
              angle: (i - (count - 1) / 2) * 0.17,
              alignment: const Alignment(0, 2.0),
              child: const CartaUnoWidget(
                card: UnoCard(id: 'back', color: UnoColor.red, type: UnoType.number),
                isFaceUp: false,
                width: 48,
                height: 72,
              ),
            ),
        ],
      ),
    );
  }
}
