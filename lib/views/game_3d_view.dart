import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/player_model.dart';
import '../viewmodels/game_viewmodel.dart';
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
  Timer? _motionTimer;

  @override
  void initState() {
    super.initState();
    _gameViewModel = GameViewModel();

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
    _gameViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.sensorViewModel,
        widget.lobbyViewModel,
        _gameViewModel,
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
            actions: <Widget>[
              IconButton(
                tooltip: 'Calibrar Posición',
                icon: const Icon(Icons.center_focus_strong),
                onPressed: widget.sensorViewModel.calibrateCurrentPosition,
              ),
            ],
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
                  lobbyViewModel: widget.lobbyViewModel,
                ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              gameViewModel.topCard != null ? 'CIMA: ${gameViewModel.topCard!.displayLabel}' : 'MESA UNO',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
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

  const _LocalHand3D({
    required this.sensorViewModel,
    required this.mySeatIndex,
  });

  @override
  Widget build(BuildContext context) {
    final vmath.Quaternion q = sensorViewModel.rotationQuaternion;
    final vmath.Vector3 normal = q.rotate(vmath.Vector3(0, 0, 1));
    final bool isFrontVisible = normal.z > 0;

    final Matrix4 handMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0018)
      ..multiply(vmath.Matrix4.compose(vmath.Vector3.zero(), q, vmath.Vector3(1.0, 1.0, 1.0)));

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
                child: Text(
                  isFrontVisible ? 'TU MANO (3D)' : 'REVERSO',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameStatusOverlay extends StatelessWidget {
  final GameViewModel gameViewModel;
  final LobbyViewModel lobbyViewModel;

  const _GameStatusOverlay({
    required this.gameViewModel,
    required this.lobbyViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: <Widget>[
          Text(
            gameViewModel.statusMessage,
            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
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
