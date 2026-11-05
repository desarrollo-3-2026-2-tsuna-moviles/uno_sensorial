import 'package:flutter/material.dart';
import '../../models/card_model.dart';

/// Widget reutilizable CartaUnoWidget (RF-15, RF-16)
class CartaUnoWidget extends StatelessWidget {
  final UnoCard card;
  final bool isFaceUp;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CartaUnoWidget({
    super.key,
    required this.card,
    this.isFaceUp = true,
    this.isSelected = false,
    this.onTap,
    this.width = 64.0,
    this.height = 96.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 48.0,
        minHeight: 48.0,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: isSelected ? 16.0 : 0.0),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isFaceUp ? card.displayColor : const Color(0xFFB71C1C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.amberAccent : Colors.white,
              width: isSelected ? 3.5 : 2.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isSelected ? Colors.amberAccent.withValues(alpha: 0.5) : Colors.black45,
                blurRadius: isSelected ? 12 : 6,
                offset: Offset(0, isSelected ? 8 : 4),
              ),
            ],
          ),
          child: isFaceUp ? _buildFrontFace() : _buildBackFace(),
        ),
      ),
    );
  }

  Widget _buildFrontFace() {
    return Stack(
      children: <Widget>[
        Center(
          child: Transform.rotate(
            angle: -0.25,
            child: Container(
              width: width * 0.75,
              height: height * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.elliptical(width * 0.75, height * 0.5)),
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            card.displayLabel,
            style: TextStyle(
              color: card.color == UnoColor.wild ? Colors.black : card.displayColor,
              fontWeight: FontWeight.w900,
              fontSize: height * 0.35,
              shadows: const <Shadow>[
                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
              ],
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 6,
          child: Text(
            card.displayLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 6,
          child: Text(
            card.displayLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackFace() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Transform.rotate(
          angle: -0.25,
          child: Container(
            width: width * 0.8,
            height: height * 0.45,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.all(Radius.elliptical(width * 0.8, height * 0.45)),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Center(
              child: Text(
                'UNO',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
