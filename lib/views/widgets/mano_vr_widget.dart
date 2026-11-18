import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import 'carta_uno_widget.dart';

/// Mano del jugador local en abanico, sostenida frente a él.
/// Toca una carta para levantarla y tócala de nuevo para jugarla.
class ManoVrWidget extends StatefulWidget {
  const ManoVrWidget({
    super.key,
    required this.cards,
    required this.onPlayCard,
    this.isHandSelected = false,
    this.isFaceUp = true,
  });

  static const Size size = Size(380, 150);

  final List<UnoCard> cards;
  final void Function(UnoCard card) onPlayCard;
  final bool isHandSelected;

  /// false cuando la mano está girada y se ve su reverso.
  final bool isFaceUp;

  @override
  State<ManoVrWidget> createState() => _ManoVrWidgetState();
}

class _ManoVrWidgetState extends State<ManoVrWidget> {
  String? _selectedCardId;

  @override
  Widget build(BuildContext context) {
    final int count = widget.cards.length;
    final double step = count <= 1 ? 0 : min(0.14, 1.3 / (count - 1));

    return Container(
      width: ManoVrWidget.size.width,
      height: ManoVrWidget.size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: widget.isHandSelected
            ? const Color(0xFF003366).withValues(alpha: 0.55)
            : Colors.black.withValues(alpha: 0.18),
        border: Border.all(
          color: widget.isHandSelected ? Colors.amberAccent : Colors.white12,
          width: widget.isHandSelected ? 2.0 : 1.0,
        ),
        boxShadow: widget.isHandSelected
            ? <BoxShadow>[BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.4), blurRadius: 18, spreadRadius: 2)]
            : null,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          for (int i = 0; i < count; i++) _card(widget.cards[i], (i - (count - 1) / 2) * step),
        ],
      ),
    );
  }

  Widget _card(UnoCard card, double angle) {
    final bool isSelected = _selectedCardId == card.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Transform.rotate(
        angle: angle,
        alignment: const Alignment(0, 2.4),
        child: CartaUnoWidget(
          card: card,
          isFaceUp: widget.isFaceUp,
          isSelected: isSelected,
          width: 64,
          height: 96,
          onTap: () {
            if (isSelected) {
              widget.onPlayCard(card);
              setState(() => _selectedCardId = null);
            } else {
              setState(() => _selectedCardId = card.id);
            }
          },
        ),
      ),
    );
  }
}
