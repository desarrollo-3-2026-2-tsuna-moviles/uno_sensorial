import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../services/gesture_service.dart';
import '../viewmodels/game_viewmodel.dart';
import '../viewmodels/gesture_viewmodel.dart';
import '../viewmodels/lobby_viewmodel.dart';
import '../viewmodels/sensor_viewmodel.dart';

/// Vista de la Mesa Circular 3D en la arquitectura MVVM
class Game3DView extends StatefulWidget {
  final LobbyViewModel lobbyViewModel;
  final SensorViewModel sensorViewModel;

  const Game3DView({
    super.key,
    required this.lobbyViewModel,
    required this.sensorViewModel,
  });

  @override
  State<Game3DView> createState() => _Game3DViewState();
}

class _Game3DViewState extends State<Game3DView> {
  late final GameViewModel _gameViewModel;
  late final GestureViewModel _gestureViewModel;
  Timer? _motionTimer;
  Timer? _calibrationFeedbackTimer;
  bool _showCalibrated = false;

  @override
  void initState() {
    super.initState();
    _gameViewModel = GameViewModel(seatIndex: widget.lobbyViewModel.mySeatIndex);
    _gestureViewModel = GestureViewModel(
      gameViewModel: _gameViewModel,
      sensorViewModel: widget.sensorViewModel,
    );

    // Broadcast de la orientación 3D local al servidor LAN
    _motionTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (widget.lobbyViewModel.isConnected) {
        widget.lobbyViewModel.netService.sendLocalMotion(widget.sensorViewModel.rotationQuaternion);
      }
    });
  }

  @override
  void dispose() {
    _motionTimer?.cancel();
    _calibrationFeedbackTimer?.cancel();
    _gestureViewModel.dispose();
    _gameViewModel.dispose();
    super.dispose();
  }

  /// RF-23: toma la orientación actual como punto cero al instante,
  /// sin pausar la partida (solo muestra una confirmación breve).
  void _calibrate() {
    widget.sensorViewModel.calibrateCurrentPosition();
    _calibrationFeedbackTimer?.cancel();
    setState(() => _showCalibrated = true);
    _calibrationFeedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showCalibrated = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.sensorViewModel,
        widget.lobbyViewModel,
        _gameViewModel,
        _gestureViewModel,
      ]),
      builder: (BuildContext context, Widget? child) {
        final List<PlayerModel> players = widget.lobbyViewModel.players;
        final int totalPlayers = max(players.length, 2);
        final int mySeatIndex = widget.lobbyViewModel.mySeatIndex;
        final double mySeatAngle = (2 * pi * mySeatIndex) / totalPlayers;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mesa UNO 3D - MVVM'),
            centerTitle: true,
          ),
          body: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Fondo cuadrícula
              const _BackgroundGrid(),

              // Mesa Circular y Jugadores en Perspectiva 3D
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    _CircularTable3D(gameViewModel: _gameViewModel),

                    // Oponentes
                    for (final PlayerModel player in players)
                      if (player.id != widget.lobbyViewModel.myPlayerId)
                        _OpponentHand3D(
                          player: player,
                          totalPlayers: totalPlayers,
                          mySeatAngle: mySeatAngle,
                          lobbyViewModel: widget.lobbyViewModel,
                        ),

                    // Jugador Local
                    _LocalHand3D(
                      sensorViewModel: widget.sensorViewModel,
                      mySeatIndex: mySeatIndex,
                      selectedCard: _gameViewModel.selectedCard,
                    ),
                  ],
                ),
              ),

              // Superposición de Estado de Juego
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _GameStatusOverlay(
                  gameViewModel: _gameViewModel,
                  gestureViewModel: _gestureViewModel,
                ),
              ),

              // RF-21: aviso de Reversa pendiente + botón táctil equivalente (RF-24)
              if (_gameViewModel.isAwaitingReverseConfirmation)
                Positioned(
                  top: 120,
                  left: 24,
                  right: 24,
                  child: _ReversePrompt(onConfirm: _gameViewModel.confirmReverse),
                ),

              // RF-23: botón de calibración siempre visible en el HUD
              Positioned(
                right: 12,
                top: 190,
                child: _CalibrateButton(
                  showConfirmation: _showCalibrated,
                  onPressed: _calibrate,
                ),
              ),

              // Mano del jugador + botones táctiles equivalentes a los gestos (RF-24)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _HandHud(gameViewModel: _gameViewModel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircularTable3D extends StatelessWidget {
  final GameViewModel gameViewModel;

  const _CircularTable3D({required this.gameViewModel});

  @override
  Widget build(BuildContext context) {
    final Matrix4 tableMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateX(0.85);

    final UnoCard? top = gameViewModel.topCard;

    return Transform(
      transform: tableMatrix,
      alignment: Alignment.center,
      child: Container(
        width: 330,
        height: 330,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: <Color>[Color(0xFF1B5E20), Color(0xFF0D3B11)],
          ),
          border: Border.all(color: Colors.amber, width: 6),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 35,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: top == null
              ? const Text('MESA UNO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              : _UnoCardFace(card: top, width: 70, height: 104),
        ),
      ),
    );
  }
}

class _OpponentHand3D extends StatelessWidget {
  final PlayerModel player;
  final int totalPlayers;
  final double mySeatAngle;
  final LobbyViewModel lobbyViewModel;

  const _OpponentHand3D({
    required this.player,
    required this.totalPlayers,
    required this.mySeatAngle,
    required this.lobbyViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final double opponentAngle = (2 * pi * player.seatIndex) / totalPlayers;
    final double relativeAngle = opponentAngle - mySeatAngle;

    const double radius = 160.0;
    final double dx = radius * sin(relativeAngle);
    final double dy = -radius * cos(relativeAngle);

    final vmath.Quaternion remoteQ = lobbyViewModel.playerOrientations[player.id] ?? vmath.Quaternion.identity();
    final vmath.Vector3 normal = remoteQ.rotate(vmath.Vector3(0, 0, 1));
    final bool isBackFacingMe = normal.z <= 0;

    final Matrix4 opponentMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateX(0.7)
      ..multiply(vmath.Matrix4.compose(vmath.Vector3.zero(), remoteQ, vmath.Vector3(1.0, 1.0, 1.0)));

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
            child: Text(player.name, style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
          ),
          const SizedBox(height: 4),
          Transform(
            transform: opponentMatrix,
            alignment: Alignment.center,
            child: Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: isBackFacingMe ? const Color(0xFFB71C1C) : const Color(0xFF0055B8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  isBackFacingMe ? 'UNO' : 'MANO 3D',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalHand3D extends StatelessWidget {
  final SensorViewModel sensorViewModel;
  final int mySeatIndex;
  final UnoCard? selectedCard;

  const _LocalHand3D({
    required this.sensorViewModel,
    required this.mySeatIndex,
    required this.selectedCard,
  });

  @override
  Widget build(BuildContext context) {
    final vmath.Quaternion q = sensorViewModel.rotationQuaternion;
    final vmath.Vector3 normal = q.rotate(vmath.Vector3(0, 0, 1));
    final bool isFrontVisible = normal.z > 0;

    final Matrix4 handMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0018)
      ..multiply(vmath.Matrix4.compose(vmath.Vector3.zero(), q, vmath.Vector3(1.0, 1.0, 1.0)));

    final UnoCard? card = selectedCard;

    return Positioned(
      bottom: 110,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)),
            child: Text('TU MANO (Asiento ${mySeatIndex + 1})', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          Transform(
            transform: handMatrix,
            alignment: Alignment.center,
            child: Container(
              width: 210,
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFrontVisible
                      ? <Color>[const Color(0xFF0055B8), const Color(0xFF0088FF)]
                      : <Color>[const Color(0xFFB71C1C), const Color(0xFFD32F2F)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: !isFrontVisible
                    ? const Text('REVERSO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    : card != null
                        ? _UnoCardFace(card: card, width: 62, height: 92)
                        : const Text('TU MANO (3D)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado del juego, sentido de juego animado (RF-21) e indicador de "¡UNO!" (RF-22).
class _GameStatusOverlay extends StatelessWidget {
  final GameViewModel gameViewModel;
  final GestureViewModel gestureViewModel;

  const _GameStatusOverlay({
    required this.gameViewModel,
    required this.gestureViewModel,
  });

  static String _gestureLabel(GestureType gesture) {
    switch (gesture) {
      case GestureType.throwCard:
        return 'Gesto: lanzar';
      case GestureType.reverseTwist:
        return 'Gesto: giro';
      case GestureType.unoShake:
        return 'Gesto: sacudida';
    }
  }

  @override
  Widget build(BuildContext context) {
    final GestureType? lastGesture = gestureViewModel.lastGesture;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              // RF-21: animación del cambio de sentido (media vuelta por cada Reversa).
              AnimatedRotation(
                turns: gameViewModel.reverseCount * 0.5,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutBack,
                child: Icon(
                  gameViewModel.isClockwise ? Icons.rotate_right : Icons.rotate_left,
                  color: Colors.lightBlueAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                gameViewModel.isClockwise ? 'Horario' : 'Antihorario',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const Spacer(),
              if (lastGesture != null)
                Text(
                  _gestureLabel(lastGesture),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              const SizedBox(width: 8),
              // RF-22: indicador de UNO cantado.
              AnimatedScale(
                scale: gameViewModel.unoCalled ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    '¡UNO!',
                    style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            gameViewModel.statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// RF-21: aviso para confirmar la Reversa con un giro (o con el botón, RF-24).
class _ReversePrompt extends StatelessWidget {
  final VoidCallback onConfirm;

  const _ReversePrompt({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.deepPurple.shade700,
      borderRadius: BorderRadius.circular(14),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            const Icon(Icons.screen_rotation, color: Colors.white),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Gira el teléfono para cambiar el sentido',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: onConfirm,
              style: TextButton.styleFrom(foregroundColor: Colors.amberAccent),
              child: const Text('Cambiar sentido'),
            ),
          ],
        ),
      ),
    );
  }
}

/// RF-23: botón de calibración siempre visible; confirma con un check breve.
class _CalibrateButton extends StatelessWidget {
  final bool showConfirmation;
  final VoidCallback onPressed;

  const _CalibrateButton({required this.showConfirmation, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Calibrar (tomar posición actual como cero)',
      child: FloatingActionButton.small(
        heroTag: 'calibrate',
        onPressed: onPressed,
        backgroundColor: showConfirmation ? Colors.green : Colors.blueAccent,
        foregroundColor: Colors.white,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            showConfirmation ? Icons.check : Icons.center_focus_strong,
            key: ValueKey<bool>(showConfirmation),
          ),
        ),
      ),
    );
  }
}

/// Mano del jugador (tocar para seleccionar) y botones táctiles equivalentes
/// a cada gesto (RF-24): Jugar (RF-20) y ¡UNO! (RF-22), además de Robar.
class _HandHud extends StatelessWidget {
  final GameViewModel gameViewModel;

  const _HandHud({required this.gameViewModel});

  @override
  Widget build(BuildContext context) {
    final List<UnoCard> hand = gameViewModel.hand;
    final UnoCard? selected = gameViewModel.selectedCard;

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.transparent, Colors.black87],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: gameViewModel.drawCard,
                  icon: const Icon(Icons.add_card, size: 18),
                  label: const Text('Robar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: selected == null ? null : gameViewModel.playSelectedCard,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Jugar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: gameViewModel.callUno,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gameViewModel.canCallUno ? Colors.red : Colors.red.shade900,
                    foregroundColor: Colors.yellow,
                  ),
                  child: const Text('¡UNO!', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: hand.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (BuildContext context, int index) {
                  final UnoCard card = hand[index];
                  final bool isSelected = identical(card, selected);
                  final bool isPlayable = gameViewModel.isValidPlay(card);
                  return GestureDetector(
                    onTap: () => gameViewModel.selectCard(card),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(top: isSelected ? 0 : 12),
                      child: Opacity(
                        opacity: isPlayable ? 1.0 : 0.45,
                        child: _UnoCardFace(card: card, width: 54, height: 80, highlighted: isSelected),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cara de una carta UNO (color + símbolo).
class _UnoCardFace extends StatelessWidget {
  final UnoCard card;
  final double width;
  final double height;
  final bool highlighted;

  const _UnoCardFace({
    required this.card,
    required this.width,
    required this.height,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: card.displayColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlighted ? Colors.amberAccent : Colors.white, width: highlighted ? 3 : 2),
        boxShadow: highlighted
            ? <BoxShadow>[BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.6), blurRadius: 10)]
            : null,
      ),
      child: Center(
        child: Text(
          card.displayLabel,
          style: TextStyle(
            color: card.color == UnoColor.yellow ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: height * 0.3,
          ),
        ),
      ),
    );
  }
}

class _BackgroundGrid extends StatelessWidget {
  const _BackgroundGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
