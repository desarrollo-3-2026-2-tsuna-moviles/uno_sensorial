import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';

/// ViewModel que gestiona la lógica del juego UNO del jugador local:
/// baraja, mano, validación de jugadas (RF-10), Reversa (RF-21) y "¡UNO!" (RF-22).
///
/// Por ahora el juego es local (un solo dispositivo): la sincronización de la
/// partida por red se implementa en otro issue, así que siempre es tu turno.
class GameViewModel extends ChangeNotifier {
  GameViewModel({
    Random? random,
    int initialHandSize = 7,
    String playerName = 'Tú',
    int seatIndex = 0,
  })  : _random = random ?? Random(),
        localPlayer = PlayerModel(id: 'local', name: playerName, seatIndex: seatIndex) {
    _initializeDeck();
    for (int i = 0; i < initialHandSize; i++) {
      final UnoCard? card = _drawFromDeck();
      if (card != null) localPlayer.cards.add(card);
    }
  }

  final Random _random;
  final PlayerModel localPlayer;

  final List<UnoCard> _deck = <UnoCard>[];
  final List<UnoCard> _discardPile = <UnoCard>[];

  UnoCard? _selectedCard;
  bool _isClockwise = true;
  bool _awaitingReverseConfirmation = false;
  int _reverseCount = 0;
  bool _unoCalled = false;
  String _statusMessage = '¡Bienvenido a UNO LAN 3D! Toca una carta para seleccionarla.';

  List<UnoCard> get hand => List<UnoCard>.unmodifiable(localPlayer.cards);
  List<UnoCard> get discardPile => List<UnoCard>.unmodifiable(_discardPile);
  UnoCard? get topCard => _discardPile.isNotEmpty ? _discardPile.last : null;
  UnoCard? get selectedCard => _selectedCard;
  bool get isClockwise => _isClockwise;
  String get statusMessage => _statusMessage;

  /// RF-21: tras jugar una Reversa, el cambio de sentido espera un giro del teléfono
  /// (o el botón táctil equivalente).
  bool get isAwaitingReverseConfirmation => _awaitingReverseConfirmation;

  /// Número de cambios de sentido confirmados (sirve para disparar la animación).
  int get reverseCount => _reverseCount;

  bool get unoCalled => _unoCalled;

  /// Juego local: siempre es tu turno, salvo mientras se confirma una Reversa.
  bool get isMyTurn => !_awaitingReverseConfirmation;

  /// RF-22: se puede cantar UNO con 1 carta, o con 2 cuando estás por jugar una.
  bool get canCallUno {
    final int count = localPlayer.cards.length;
    return count == 1 || (count == 2 && isMyTurn);
  }

  /// Genera una baraja estándar de UNO y la baraja.
  void _initializeDeck() {
    _deck.clear();
    int cardId = 0;

    for (final UnoColor color in UnoColor.values) {
      if (color == UnoColor.wild) continue;

      // Cartas 0-9
      for (int i = 0; i <= 9; i++) {
        _deck.add(UnoCard(id: 'card_${cardId++}', color: color, type: UnoType.number, number: i));
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

    _deck.shuffle(_random);

    // Iniciar pila de descartes con una carta numérica
    final UnoCard initialCard = _deck.firstWhere((UnoCard c) => c.type == UnoType.number);
    _deck.remove(initialCard);
    _discardPile.add(initialCard);
  }

  /// Saca una carta del mazo; si se acaba, rebaraja los descartes (menos la cima).
  UnoCard? _drawFromDeck() {
    if (_deck.isEmpty && _discardPile.length > 1) {
      final UnoCard top = _discardPile.removeLast();
      _deck.addAll(_discardPile);
      _discardPile
        ..clear()
        ..add(top);
      _deck.shuffle(_random);
    }
    return _deck.isEmpty ? null : _deck.removeLast();
  }

  /// RF-10: una carta se puede jugar si coincide en color, número o símbolo
  /// con la carta superior, o si es comodín.
  bool isValidPlay(UnoCard card) {
    final UnoCard? top = topCard;
    if (top == null) return true;
    if (card.color == UnoColor.wild) return true;
    // Simplificación: aún no hay selector de color para comodines, así que
    // sobre un comodín se acepta cualquier carta.
    if (top.color == UnoColor.wild) return true;
    if (card.color == top.color) return true;
    if (card.type == UnoType.number && top.type == UnoType.number && card.number == top.number) return true;
    if (card.type != UnoType.number && card.type == top.type) return true;
    return false;
  }

  /// Selecciona (o deselecciona) una carta de la mano.
  void selectCard(UnoCard card) {
    if (!localPlayer.cards.contains(card)) return;
    _selectedCard = identical(_selectedCard, card) ? null : card;
    _statusMessage = _selectedCard == null
        ? 'Carta deseleccionada'
        : 'Seleccionada ${_selectedCard!.displayLabel}: lánzala con un gesto o pulsa Jugar';
    notifyListeners();
  }

  /// RF-20: juega la carta seleccionada aplicando la validación de RF-10.
  /// La llaman tanto el gesto de lanzar como el botón táctil "Jugar".
  bool playSelectedCard() {
    final UnoCard? card = _selectedCard;

    if (_awaitingReverseConfirmation) {
      _statusMessage = 'Primero confirma el cambio de sentido (gira el teléfono)';
    } else if (card == null) {
      _statusMessage = 'Selecciona una carta antes de lanzarla';
    } else if (!isValidPlay(card)) {
      _statusMessage = 'No puedes jugar ${card.displayLabel} sobre ${topCard?.displayLabel}';
    } else {
      localPlayer.cards.remove(card);
      _discardPile.add(card);
      _selectedCard = null;
      _statusMessage = 'Jugaste ${card.displayLabel}';

      if (localPlayer.cards.isEmpty) {
        _statusMessage = '¡Ganaste la partida!';
      } else if (localPlayer.cards.length == 1 && !_unoCalled) {
        _statusMessage = 'Jugaste ${card.displayLabel}. ¡Te faltó cantar UNO!';
      }

      if (card.type == UnoType.reverse) {
        _awaitingReverseConfirmation = true;
        _statusMessage = 'Reversa: gira el teléfono para cambiar el sentido';
      }

      notifyListeners();
      return true;
    }

    notifyListeners();
    return false;
  }

  /// Roba una carta del mazo (alternativa cuando no tienes jugada válida).
  void drawCard() {
    if (_awaitingReverseConfirmation) {
      _statusMessage = 'Primero confirma el cambio de sentido (gira el teléfono)';
      notifyListeners();
      return;
    }
    final UnoCard? card = _drawFromDeck();
    if (card == null) {
      _statusMessage = 'No quedan cartas en el mazo';
    } else {
      localPlayer.cards.add(card);
      if (localPlayer.cards.length > 2) _unoCalled = false;
      _statusMessage = 'Robaste ${card.displayLabel}';
    }
    notifyListeners();
  }

  /// RF-21: confirma el cambio de sentido tras jugar una Reversa.
  /// La llaman tanto el gesto de giro como el botón táctil "Cambiar sentido".
  bool confirmReverse() {
    if (!_awaitingReverseConfirmation) return false;
    _isClockwise = !_isClockwise;
    _awaitingReverseConfirmation = false;
    _reverseCount++;
    _statusMessage = 'Sentido cambiado: ${_isClockwise ? 'horario' : 'antihorario'}';
    notifyListeners();
    return true;
  }

  /// RF-22: canta "¡UNO!" si las cartas lo permiten.
  /// La llaman tanto el gesto de sacudida como el botón táctil "¡UNO!".
  bool callUno() {
    if (!canCallUno) {
      _statusMessage = 'Solo puedes cantar UNO con 1 carta, o con 2 en tu turno';
      notifyListeners();
      return false;
    }
    _unoCalled = true;
    _statusMessage = '¡UNO!';
    notifyListeners();
    return true;
  }

  /// Solo para tests: fija la mano y la carta superior.
  @visibleForTesting
  void debugSetState({required List<UnoCard> hand, required UnoCard top}) {
    localPlayer.cards
      ..clear()
      ..addAll(hand);
    _discardPile
      ..clear()
      ..add(top);
    _selectedCard = null;
    _unoCalled = false;
    _awaitingReverseConfirmation = false;
    notifyListeners();
  }
}
