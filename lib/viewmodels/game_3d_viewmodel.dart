import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/card_model.dart';
import '../models/physics_body_model.dart';
import '../models/player_model.dart';
import '../services/mock_physics_service.dart';
import '../services/physics_engine_interface.dart';

/// ViewModel que unifica el escenario 3D para Solo Mode y Multijugador LAN,
/// alimentándose de la interfaz abstracta del motor de físicas.
class Game3DViewModel extends ChangeNotifier {
  final PhysicsEngineInterface physicsEngine = MockPhysicsService();
  Timer? _physicsLoopTimer;

  bool _isMultiplayer = false;
  int _botCount = 2;
  String _difficulty = 'Normal';

  final List<PlayerModel> _players = <PlayerModel>[];
  final List<UnoCard> _discardPile = <UnoCard>[];
  final int _currentTurnIndex = 0;
  String _statusMessage = 'Escenario 3D Iniciado';

  List<PlayerModel> get players => List<PlayerModel>.unmodifiable(_players);
  List<UnoCard> get discardPile => List<UnoCard>.unmodifiable(_discardPile);
  UnoCard? get topCard => _discardPile.isNotEmpty ? _discardPile.last : null;
  int get currentTurnIndex => _currentTurnIndex;
  String get statusMessage => _statusMessage;
  bool get isMultiplayer => _isMultiplayer;

  Game3DViewModel() {
    _initPhysics();
    _startPhysicsLoop();
  }

  void setupSoloGame({required int botCount, required String difficulty}) {
    _isMultiplayer = false;
    _botCount = botCount;
    _difficulty = difficulty;

    _players.clear();
    _players.add(PlayerModel(
      id: 'local_player',
      name: 'Tú',
      seatIndex: 0,
      cards: <UnoCard>[
        const UnoCard(id: 'c1', color: UnoColor.red, type: UnoType.number, number: 7),
        const UnoCard(id: 'c2', color: UnoColor.yellow, type: UnoType.drawTwo),
        const UnoCard(id: 'c3', color: UnoColor.green, type: UnoType.number, number: 3),
      ],
    ));

    for (int i = 1; i <= _botCount; i++) {
      _players.add(PlayerModel(
        id: 'bot_$i',
        name: 'Bot $i ($_difficulty)',
        seatIndex: i,
        cards: <UnoCard>[
          const UnoCard(id: 'b1', color: UnoColor.blue, type: UnoType.number, number: 5),
        ],
      ));
    }

    _statusMessage = 'Modo Solo ($botCount Bots - $_difficulty)';
    notifyListeners();
  }

  void setupMultiplayerGame(List<PlayerModel> lanPlayers) {
    _isMultiplayer = true;
    _players.clear();
    _players.addAll(lanPlayers);
    _statusMessage = 'Modo Multijugador LAN (${_players.length} Jugadores)';
    notifyListeners();
  }

  void _initPhysics() {
    physicsEngine.addBody(PhysicsBodyModel(
      id: 'table',
      position: vmath.Vector3(0, 0, 0),
    ));
    physicsEngine.addBody(PhysicsBodyModel(
      id: 'deck',
      position: vmath.Vector3(-0.5, 0, 0),
    ));
    physicsEngine.addBody(PhysicsBodyModel(
      id: 'discard',
      position: vmath.Vector3(0.5, 0, 0),
    ));

    _discardPile.add(const UnoCard(
      id: 'initial',
      color: UnoColor.red,
      type: UnoType.number,
      number: 7,
    ));
  }

  void _startPhysicsLoop() {
    _physicsLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      physicsEngine.stepSimulation(0.016);
      notifyListeners();
    });
  }

  void shoutUno(String playerName) {
    _statusMessage = '¡$playerName gritó UNO! 🃏';
    notifyListeners();
  }

  @override
  void dispose() {
    _physicsLoopTimer?.cancel();
    physicsEngine.dispose();
    super.dispose();
  }
}
