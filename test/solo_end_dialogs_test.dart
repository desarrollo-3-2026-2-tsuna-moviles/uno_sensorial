import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_game/models/card_model.dart';
import 'package:uno_game/models/player_model.dart';
import 'package:uno_game/views/widgets/end_game_dialog.dart';
import 'package:uno_game/views/widgets/solo_config_modal.dart';

void main() {
  testWidgets('el modal de Un Jugador entrega bots y dificultad elegidos', (WidgetTester tester) async {
    int? bots;
    String? difficulty;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SoloConfigModal(onStartGame: (int b, String d) {
          bots = b;
          difficulty = d;
        }),
      ),
    ));

    await tester.tap(find.text('Difícil'));
    await tester.pump();
    await tester.tap(find.textContaining('Jugar'));
    await tester.pump();

    expect(bots, 2);
    expect(difficulty, 'Difícil');
  });

  testWidgets('la dificultad por defecto es Normal', (WidgetTester tester) async {
    String? difficulty;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SoloConfigModal(onStartGame: (int b, String d) => difficulty = d)),
    ));
    await tester.tap(find.textContaining('Jugar'));
    await tester.pump();
    expect(difficulty, 'Normal');
  });

  testWidgets('el fin de partida muestra al ganador, el resumen y los botones', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const UnoCard card = UnoCard(id: 'c', color: UnoColor.red, type: UnoType.number, number: 1);
    final PlayerModel me = PlayerModel(id: 'me', name: 'Tú', seatIndex: 0, cards: <UnoCard>[card, card]);
    final PlayerModel bot = PlayerModel(id: 'b1', name: 'Bot 1', seatIndex: 1);
    bool again = false;
    bool exited = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EndGameDialog(
          winner: bot,
          players: <PlayerModel>[me, bot],
          localPlayerId: 'me',
          onPlayAgain: () => again = true,
          onExit: () => exited = true,
        ),
      ),
    ));
    expect(tester.takeException(), isNull);

    expect(find.text('Ganó Bot 1'), findsOneWidget);
    expect(find.text('Sin cartas'), findsOneWidget);
    expect(find.text('2 cartas'), findsOneWidget);

    await tester.ensureVisible(find.text('Jugar de nuevo'));
    await tester.tap(find.text('Jugar de nuevo'));
    await tester.ensureVisible(find.text('Volver al menú'));
    await tester.tap(find.text('Volver al menú'));
    expect(again && exited, isTrue);
  });
}
