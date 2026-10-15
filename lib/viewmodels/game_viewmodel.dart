import 'dart:math';
import 'package:flutter/widgets.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';

/// ViewModel que gestiona la lógica del juego UNO (baraja, turno, validación de jugadas)
class GameViewModel extends ChangeNotifier {
  final List<UnoCard> _deck = <UnoCard>[];
  final List<UnoCard> _discardPile = <UnoCard>[];

  int _currentTurnSeatIndex = 0;
  final bool _isClockwise = true;
  String _statusMessage = '¡Bienvenido a UNO LAN 3D!';

  List<UnoCard> get discardPile => List<UnoCard>.unmodifiable(_discardPile);
  UnoCard? get topCard => _discardPile.isNotEmpty ? _discardPile.last : null;
  int get currentTurnSeatIndex => _currentTurnSeatIndex;
  String get statusMessage => _statusMessage;

  GameViewModel() {
    _initializeDeck();
  }

  /// Genera una baraja completa estándar de UNO
  void _initializeDeck() {
    _deck.clear();
    int cardId = 0;

    for (final UnoColor color in UnoColor.values) {
      if (color == UnoColor.wild) continue;

      // Cartas 0-9
      for (int i = 0; i <= 9; i++) {
        _deck.add(UnoCard(
          id: 'card_${cardId++}',
          color: color,
          type: UnoType.number,
          number: i,
        ));
      }

      // Cartas especiales (+2, Reversa, Salto)
      _deck.add(UnoCard(id: 'card_${cardId++}', color: color, type: UnoType.drawTwo));
      _deck.add(UnoCard(id: 'card_${cardId++}', color: color, type: UnoType.skip));
      _deck.add(UnoCard(id: 'card_${cardId++}', color: color, type: UnoType.reverse));
    }

    // Comodines
    for (int i = 0; i < 4; i++) {
      _deck.add(UnoCard(id: 'card_${cardId++}', color: UnoColor.wild, type: UnoType.wild));
      _deck.add(UnoCard(id: 'card_${cardId++}', color: UnoColor.wild, type: UnoType.wildDrawFour));
    }

    _deck.shuffle(Random());

    // Iniciar pila de descartes con una carta numérica
    final UnoCard initialCard = _deck.firstWhere((UnoCard c) => c.type == UnoType.number);
    _deck.remove(initialCard);
    _discardPile.add(initialCard);
  }

  /// Verifica si una carta se puede jugar según la carta en la cima de la mesa
  bool isValidPlay(UnoCard card) {
    if (topCard == null) return true;
    if (card.color == UnoColor.wild) return true;
    if (card.color == topCard!.color) return true;
    if (card.type == UnoType.number && topCard!.type == UnoType.number && card.number == topCard!.number) return true;
    if (card.type != UnoType.number && card.type == topCard!.type) return true;
    return false;
  }

  /// Jugar una carta de la mano del jugador
  bool playCard(PlayerModel player, UnoCard card) {
    if (player.seatIndex != _currentTurnSeatIndex) {
      _statusMessage = 'No es tu turno';
      notifyListeners();
      return false;
    }

    if (!isValidPlay(card)) {
      _statusMessage = 'Carta no válida sobre ${topCard?.displayLabel}';
      notifyListeners();
      return false;
    }

    player.cards.remove(card);
    _discardPile.add(card);
    _statusMessage = '${player.name} jugó ${card.displayLabel}';

    _advanceTurn(playerCount: 4);
    notifyListeners();
    return true;
  }

  void _advanceTurn({required int playerCount}) {
    if (_isClockwise) {
      _currentTurnSeatIndex = (_currentTurnSeatIndex + 1) % playerCount;
    } else {
      _currentTurnSeatIndex = (_currentTurnSeatIndex - 1 + playerCount) % playerCount;
    }
  }
}
