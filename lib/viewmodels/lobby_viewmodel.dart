import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/player_model.dart';
import '../services/lan_network_service.dart';

/// ViewModel que conecta la interfaz del Lobby LAN con la lógica de red
class LobbyViewModel extends ChangeNotifier {
  final LanNetworkService netService;

  bool _isLoading = false;

  LobbyViewModel({required this.netService}) {
    netService.addListener(notifyListeners);
  }

  bool get isLoading => _isLoading;
  String get localIp => netService.localIp;
  bool get isHost => netService.isHost;
  bool get isConnected => netService.isConnected;
  String get myPlayerId => netService.myPlayerId;
  int get mySeatIndex => netService.mySeatIndex;
  bool get gameStarted => netService.gameStarted;

  List<PlayerModel> get players {
    return netService.players
        .map((PlayerInfo p) => PlayerModel(
              id: p.id,
              name: p.name,
              seatIndex: p.seatIndex,
            ))
        .toList();
  }

  Map<String, vmath.Quaternion> get playerOrientations => netService.playerOrientations;

  Future<void> fetchLocalIp() async {
    await netService.fetchLocalIp();
  }

  Future<bool> startHost(String playerName) async {
    _isLoading = true;
    notifyListeners();
    final bool success = await netService.startHost(playerName: playerName);
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> connectToHost(String hostIp, String playerName) async {
    _isLoading = true;
    notifyListeners();
    final bool success = await netService.connectToHost(hostIp, playerName: playerName);
    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Solo el host: inicia la partida para todos
  void startGame() {
    netService.sendStartGame();
  }

  /// RF-29/RF-30: Empieza a enviar la orientación a 20 Hz
  void startMotionSync(vmath.Quaternion Function() leerRotacion) {
    netService.startMotionSync(leerRotacion);
  }

  void stopMotionSync() {
    netService.stopMotionSync();
  }

  Future<void> disconnect() async {
    await netService.stopService();
    notifyListeners();
  }

  @override
  void dispose() {
    netService.removeListener(notifyListeners);
    super.dispose();
  }
}
