import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:uno_game/models/card_model.dart';
import 'package:uno_game/models/player_model.dart';
import 'package:uno_game/views/vr/pseudo_view.dart';
import 'package:uno_game/views/widgets/table_geometry.dart';
import 'package:uno_game/views/widgets/vr_table_scene.dart';

void main() {
  group('PseudoView', () {
    PseudoView view({double yaw = 0, double pitch = 0}) =>
        PseudoView(size: const Size(800, 360), yaw: yaw, pitch: pitch, tableRadius: 260);

    test('el rival de enfrente queda centrado, y más lejos = más arriba', () {
      final Offset opposite = TableGeometry.seatPosition(2, 4, 260);
      final ScenePoint far = view().project(opposite.dx, opposite.dy, 0);
      final ScenePoint near = view().project(0, 100, 0);
      expect(far.x, closeTo(400, 1e-6));
      expect(far.y, lessThan(near.y));
      expect(far.forward, greaterThan(near.forward));
    });

    test('los rivales laterales son simétricos respecto al centro', () {
      final Offset left = TableGeometry.seatPosition(1, 4, 260);
      final Offset right = TableGeometry.seatPosition(3, 4, 260);
      final ScenePoint l = view().project(left.dx, left.dy);
      final ScenePoint r = view().project(right.dx, right.dy);
      expect(l.x + r.x, closeTo(800, 1e-6));
      expect(l.y, closeTo(r.y, 1e-6));
    });

    test('girar la cabeza a la derecha desplaza la escena a la izquierda', () {
      final ScenePoint a = view().project(0, 0);
      final ScenePoint b = view(yaw: 0.4).project(0, 0);
      expect(b.x, lessThan(a.x));
    });

    test('la cabeza queda limitada: no hay nadie detrás del jugador', () {
      expect(PseudoView.clampYaw(10), closeTo(PseudoView.maxYaw, 1e-9));
      expect(PseudoView.clampYaw(-10), closeTo(-PseudoView.maxYaw, 1e-9));
      expect(PseudoView.maxYaw, lessThan(pi / 1.5));
    });
  });

  for (final int n in <int>[2, 5, 8]) {
    testWidgets('renderiza $n jugadores en primera persona sin errores', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final List<PlayerModel> players = <PlayerModel>[
        PlayerModel(id: 'p0', name: 'Yo', seatIndex: 0, cards: const <UnoCard>[
          UnoCard(id: 'a', color: UnoColor.red, type: UnoType.number, number: 7),
          UnoCard(id: 'b', color: UnoColor.blue, type: UnoType.number, number: 2),
        ]),
        for (int i = 1; i < n; i++)
          PlayerModel(id: 'p$i', name: 'Rival $i', seatIndex: i, cards: const <UnoCard>[
            UnoCard(id: 'x', color: UnoColor.green, type: UnoType.number, number: 1),
          ]),
      ];
      final AnimationController controller = AnimationController(vsync: tester);
      addTearDown(controller.dispose);

      for (final double yaw in <double>[0, 0.8, -0.8]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: VrTableScene(
              players: players,
              currentTurnSeatIndex: 1,
              topCard: null,
              rotationController: controller,
              yaw: yaw,
              pitch: 0.1,
              handRotation: vmath.Quaternion.identity(),
              isHandSelected: false,
              onPlayCard: (_) {},
            ),
          ),
        ));
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Rival 1'), findsOneWidget);
    });
  }
}
