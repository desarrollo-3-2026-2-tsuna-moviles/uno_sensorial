import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_game/models/card_model.dart';
import 'package:uno_game/viewmodels/game_viewmodel.dart';

void main() {
  late GameViewModel game;

  const UnoCard red5 = UnoCard(id: 'r5', color: UnoColor.red, type: UnoType.number, number: 5);
  const UnoCard red7 = UnoCard(id: 'r7', color: UnoColor.red, type: UnoType.number, number: 7);
  const UnoCard blue5 = UnoCard(id: 'b5', color: UnoColor.blue, type: UnoType.number, number: 5);
  const UnoCard green2 = UnoCard(id: 'g2', color: UnoColor.green, type: UnoType.number, number: 2);
  const UnoCard redReverse = UnoCard(id: 'rr', color: UnoColor.red, type: UnoType.reverse);
  const UnoCard wild = UnoCard(id: 'w', color: UnoColor.wild, type: UnoType.wild);

  setUp(() {
    game = GameViewModel(random: Random(1));
  });

  test('reparte 7 cartas al empezar', () {
    expect(game.hand.length, 7);
    expect(game.topCard, isNotNull);
  });

  group('RF-10 / RF-20 jugar la carta seleccionada', () {
    test('sin carta seleccionada no juega nada', () {
      game.debugSetState(hand: <UnoCard>[red7, green2], top: red5);
      expect(game.playSelectedCard(), isFalse);
      expect(game.hand.length, 2);
    });

    test('juega si coincide el color', () {
      game.debugSetState(hand: <UnoCard>[red7, green2], top: red5);
      game.selectCard(red7);
      expect(game.playSelectedCard(), isTrue);
      expect(game.topCard, red7);
      expect(game.hand, <UnoCard>[green2]);
    });

    test('juega si coincide el número', () {
      game.debugSetState(hand: <UnoCard>[blue5, green2], top: red5);
      game.selectCard(blue5);
      expect(game.playSelectedCard(), isTrue);
    });

    test('un comodín siempre se puede jugar', () {
      game.debugSetState(hand: <UnoCard>[wild, green2], top: red5);
      game.selectCard(wild);
      expect(game.playSelectedCard(), isTrue);
    });

    test('rechaza una carta que no coincide', () {
      game.debugSetState(hand: <UnoCard>[green2, red7], top: red5);
      game.selectCard(green2);
      expect(game.playSelectedCard(), isFalse);
      expect(game.topCard, red5);
      expect(game.hand.length, 2);
    });
  });

  group('RF-21 Reversa', () {
    test('jugar una Reversa espera la confirmación y luego cambia el sentido', () {
      game.debugSetState(hand: <UnoCard>[redReverse, green2, red7], top: red5);
      game.selectCard(redReverse);
      game.playSelectedCard();

      expect(game.isAwaitingReverseConfirmation, isTrue);
      expect(game.isClockwise, isTrue);

      // Mientras espera, no se puede jugar otra carta.
      game.selectCard(red7);
      expect(game.playSelectedCard(), isFalse);

      expect(game.confirmReverse(), isTrue);
      expect(game.isClockwise, isFalse);
      expect(game.isAwaitingReverseConfirmation, isFalse);
      expect(game.reverseCount, 1);
    });

    test('confirmar sin Reversa pendiente no hace nada', () {
      expect(game.confirmReverse(), isFalse);
      expect(game.isClockwise, isTrue);
    });
  });

  group('RF-22 cantar UNO', () {
    test('no se puede con 3 o más cartas', () {
      game.debugSetState(hand: <UnoCard>[red7, green2, blue5], top: red5);
      expect(game.callUno(), isFalse);
      expect(game.unoCalled, isFalse);
    });

    test('se puede con 2 cartas en tu turno', () {
      game.debugSetState(hand: <UnoCard>[red7, green2], top: red5);
      expect(game.callUno(), isTrue);
      expect(game.unoCalled, isTrue);
    });

    test('se puede con 1 carta', () {
      game.debugSetState(hand: <UnoCard>[red7], top: red5);
      expect(game.callUno(), isTrue);
    });

    test('robar hasta tener más de 2 cartas anula el UNO cantado', () {
      game.debugSetState(hand: <UnoCard>[red7, green2], top: red5);
      game.callUno();
      game.drawCard();
      expect(game.unoCalled, isFalse);
    });
  });
}
