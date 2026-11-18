import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../../models/card_model.dart';
import '../../models/player_model.dart';
import '../vr/pseudo_view.dart';
import '../vr/vr_room_painter.dart';
import 'carta_uno_widget.dart';
import 'mano_vr_widget.dart';
import 'table_geometry.dart';
import 'vr_player_widgets.dart';

/// Escena en primera persona: sala y mesa de fondo, rivales repartidos a partes
/// iguales alrededor de la mesa y, delante del jugador, su mano de cartas.
///
/// - `yaw`/`pitch`: giro de la cabeza (solo con la mano sin seleccionar).
/// - `handRotation`: giro libre de la mano (solo con la mano seleccionada).
class VrTableScene extends StatelessWidget {
  const VrTableScene({
    super.key,
    required this.players,
    required this.currentTurnSeatIndex,
    required this.topCard,
    required this.rotationController,
    required this.yaw,
    required this.pitch,
    required this.handRotation,
    required this.isHandSelected,
    required this.onPlayCard,
    this.onDrawCard,
  });

  /// Jugadores en orden de asiento: el primero es el jugador local.
  final List<PlayerModel> players;
  final int currentTurnSeatIndex;
  final UnoCard? topCard;
  final AnimationController rotationController;
  final double yaw;
  final double pitch;
  final vmath.Quaternion handRotation;
  final bool isHandSelected;
  final void Function(UnoCard card) onPlayCard;
  final VoidCallback? onDrawCard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      final Size size = constraints.biggest;
      final int n = players.isEmpty ? 1 : players.length;
      final double radius = TableGeometry.tableRadius(n);
      final PseudoView view = PseudoView(
        size: size,
        yaw: PseudoView.clampYaw(yaw),
        pitch: PseudoView.clampPitch(pitch),
        tableRadius: radius,
      );

      final int turnSeat = players.indexWhere((PlayerModel p) => p.seatIndex == currentTurnSeatIndex);

      // Rivales (fan + placa): se dibujan de lejos a cerca
      final List<({double forward, Widget widget})> standing = <({double forward, Widget widget})>[];
      for (int k = 1; k < players.length; k++) {
        final Offset dir = TableGeometry.seatPosition(k, n, 1.0);
        final PlayerModel player = players[k];
        final bool isTurn = k == turnSeat;

        final ScenePoint fan = view.project(dir.dx * (radius - 34), dir.dy * (radius - 34), 6);
        if (fan.visible) {
          standing.add((
            forward: fan.forward,
            widget: _anchored(
              view,
              fan,
              1.0,
              OpponentHandFan.size,
              OpponentHandFan(cardCount: player.cardCount),
            ),
          ));
        }

        final ScenePoint plate = view.project(dir.dx * (radius + 58), dir.dy * (radius + 58), 62);
        if (plate.visible) {
          standing.add((
            forward: plate.forward + 1,
            widget: _anchored(
              view,
              plate,
              1.15,
              PlayerNameplate.size,
              PlayerNameplate(player: player, isCurrentTurn: isTurn),
            ),
          ));
        }
      }
      standing.sort((a, b) => b.forward.compareTo(a.forward));

      final ScenePoint center = view.project(0, 0);
      final double squash = (view.eyeHeight / center.forward).clamp(0.25, 1.0);
      final double centerScale = view.screenScale(center.forward, 1.25);

      final bool faceUp = handRotation.rotated(vmath.Vector3(0, 0, 1)).z >= 0;
      final double handScale = view.ui * (isHandSelected ? 1.1 : 1.0);
      final vmath.Matrix4 handMatrix = vmath.Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..translateByDouble(0.0, isHandSelected ? -14.0 : 0.0, 0.0, 1.0)
        ..rotateX(-0.45)
        ..multiply(vmath.Matrix4.compose(vmath.Vector3.zero(), handRotation, vmath.Vector3(1, 1, 1)))
        ..scaleByDouble(handScale, handScale, handScale, 1.0);

      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(painter: VrRoomPainter(view: view, seatCount: n, turnSeat: turnSeat)),

          // Mazo, sentido de giro y descarte sobre el fieltro
          if (center.visible)
            Positioned(
              left: center.x,
              top: center.y,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: Transform(
                  transform: vmath.Matrix4.diagonal3Values(centerScale, centerScale * squash, 1),
                  alignment: Alignment.center,
                  child: _TableCenterPiece(
                    topCard: topCard,
                    rotationController: rotationController,
                    onDrawCard: onDrawCard,
                  ),
                ),
              ),
            ),

          for (final ({double forward, Widget widget}) item in standing) item.widget,

          // Mano local, delante del jugador
          Positioned(
            left: 0,
            right: 0,
            bottom: 6 * view.ui,
            child: Center(
              child: Transform(
                transform: handMatrix,
                alignment: Alignment.bottomCenter,
                child: ManoVrWidget(
                  cards: players.isEmpty ? const <UnoCard>[] : players.first.cards,
                  isHandSelected: isHandSelected,
                  isFaceUp: faceUp,
                  onPlayCard: onPlayCard,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Coloca un widget de pie con su base en el punto proyectado, escalado por distancia.
  Widget _anchored(PseudoView view, ScenePoint p, double worldScale, Size size, Widget child) {
    final double s = view.screenScale(p.forward, worldScale);
    final double dim = (0.55 + 0.45 * (view.viewerDistance / p.forward).clamp(0.0, 1.0)).clamp(0.55, 1.0);
    return Positioned(
      left: p.x,
      top: p.y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -1.0),
        child: Opacity(
          opacity: dim,
          child: Transform.scale(
            scale: s,
            alignment: Alignment.bottomCenter,
            child: SizedBox.fromSize(size: size, child: child),
          ),
        ),
      ),
    );
  }
}

class _TableCenterPiece extends StatelessWidget {
  const _TableCenterPiece({required this.topCard, required this.rotationController, this.onDrawCard});

  final UnoCard? topCard;
  final AnimationController rotationController;
  final VoidCallback? onDrawCard;

  static const double _w = 58;
  static const double _h = 86;

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
          onTap: onDrawCard,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _label('MAZO'),
              const SizedBox(height: 4),
              const CartaUnoWidget(
                card: UnoCard(id: 'deck', color: UnoColor.red, type: UnoType.number),
                isFaceUp: false,
                width: _w,
                height: _h,
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        RotationTransition(
          turns: rotationController,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: const Icon(Icons.sync, color: Colors.amberAccent, size: 26),
          ),
        ),
        const SizedBox(width: 18),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _label('DESCARTE'),
            const SizedBox(height: 4),
            if (topCard != null)
              CartaUnoWidget(card: topCard!, isFaceUp: true, width: _w, height: _h)
            else
              Container(
                width: _w,
                height: _h,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: const Center(child: Text('VACÍO', style: TextStyle(color: Colors.white38, fontSize: 10))),
              ),
          ],
        ),
      ],
    );
  }
}
