import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/lan_network_service.dart';
import 'viewmodels/game_3d_viewmodel.dart';
import 'viewmodels/lobby_viewmodel.dart';
import 'viewmodels/sensor_viewmodel.dart';
import 'views/game_3d_table_view.dart';
import 'views/login_view.dart';
import 'views/menu_view.dart';
import 'views/multiplayer_view.dart';
import 'views/settings_view.dart';
import 'views/waiting_room_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const UnoGameApp());
}

/// Aplicación Principal con navegación hacia el Escenario 3D desde el Modo Solo
class UnoGameApp extends StatelessWidget {
  const UnoGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNO Juego 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE63946),
          brightness: Brightness.dark,
        ),
      ),
      home: const _NavigationFlowHandler(),
    );
  }
}

class _NavigationFlowHandler extends StatefulWidget {
  const _NavigationFlowHandler();

  @override
  State<_NavigationFlowHandler> createState() => _NavigationFlowHandlerState();
}

class _NavigationFlowHandlerState extends State<_NavigationFlowHandler> {
  AppUser? _currentUser;
  String _currentScreen = 'login';
  String _activeRoomCode = 'ABCD12';
  bool _isRoomHost = true;

  late final SensorViewModel _sensorViewModel;

  // RF-25 a RF-30: red local (un solo servicio para toda la app)
  late final LanNetworkService _netService;
  late final LobbyViewModel _lobbyViewModel;

  @override
  void initState() {
    super.initState();
    _sensorViewModel = SensorViewModel();
    _netService = LanNetworkService();
    _lobbyViewModel = LobbyViewModel(netService: _netService);
  }

  @override
  void dispose() {
    _sensorViewModel.dispose();
    _lobbyViewModel.dispose();
    _netService.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// RF-25: Crear sala. El código de la sala es la IP de este celular.
  Future<void> _crearSala() async {
    final bool ok = await _lobbyViewModel.startHost(_currentUser!.name);
    if (!mounted) return;
    if (!ok) {
      _mostrarMensaje('No se pudo crear la sala. Revisa que estés en Wi-Fi.');
      return;
    }
    final String ip = await _netService.fetchLocalIp();
    setState(() {
      _activeRoomCode = ip;
      _isRoomHost = true;
      _currentScreen = 'waiting';
    });
  }

  /// RF-27: Unirse a una sala con la IP del anfitrión.
  Future<void> _unirseASala(String ip) async {
    final bool ok = await _lobbyViewModel.connectToHost(ip, _currentUser!.name);
    if (!mounted) return;
    if (!ok) {
      _mostrarMensaje('No se pudo conectar a $ip');
      return;
    }
    setState(() {
      _activeRoomCode = ip;
      _isRoomHost = false;
      _currentScreen = 'waiting';
    });
  }

  /// Inicia la partida en red y empieza a sincronizar los sensores a 20 Hz (RF-29/RF-30).
  void _startMultiplayerGame() {
    if (_isRoomHost) {
      _lobbyViewModel.startGame(); // avisa a todos los clientes
    }

    final int otrosJugadores = _lobbyViewModel.players.length - 1;
    final Game3DViewModel game3DVM = Game3DViewModel();
    game3DVM.setupSoloGame(botCount: otrosJugadores < 1 ? 1 : otrosJugadores, difficulty: 'Normal');

    _lobbyViewModel.startMotionSync(() => _sensorViewModel.rotationQuaternion);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Game3DTableView(
          game3DViewModel: game3DVM,
          sensorViewModel: _sensorViewModel,
          onExit: () {
            _lobbyViewModel.stopMotionSync();
            Navigator.of(context).pop();
            game3DVM.dispose();
          },
        ),
      ),
    );
  }

  Future<void> _salirDeSala() async {
    await _lobbyViewModel.disconnect();
    _navigateTo('multiplayer');
  }

  void _onLogin(AppUser user) {
    setState(() {
      _currentUser = user;
      _currentScreen = 'menu';
    });
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
      _currentScreen = 'login';
    });
  }

  void _navigateTo(String screen) {
    setState(() => _currentScreen = screen);
  }

  void _startSolo3DGame(int botCount, [String difficulty = 'Normal']) {
    final Game3DViewModel game3DVM = Game3DViewModel();
    game3DVM.setupSoloGame(botCount: botCount, difficulty: difficulty);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Game3DTableView(
          game3DViewModel: game3DVM,
          sensorViewModel: _sensorViewModel,
          onExit: () {
            Navigator.of(context).pop();
            game3DVM.dispose();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _currentScreen == 'login') {
      return LoginView(onLogin: _onLogin);
    }

    switch (_currentScreen) {
      case 'menu':
        return MenuPrincipalView(
          user: _currentUser!,
          onStartSoloGame: (int botCount, String difficulty) => _startSolo3DGame(botCount, difficulty),
          onMultiplayer: () => _navigateTo('multiplayer'),
          onSettings: () => _navigateTo('settings'),
        );

      case 'multiplayer':
        return MultiplayerView(
          onCreateRoom: (String code) => _crearSala(),
          onJoinRoom: (String ip) => _unirseASala(ip),
          onBack: () => _navigateTo('menu'),
        );

      case 'waiting':
        return WaitingRoomView(
          user: _currentUser!,
          roomCode: _activeRoomCode,
          isHost: _isRoomHost,
          lobbyViewModel: _lobbyViewModel,
          onStartGame: _startMultiplayerGame,
          onBack: _salirDeSala,
        );

      case 'settings':
        return SettingsView(
          user: _currentUser!,
          onBack: () => _navigateTo('menu'),
          onLogout: _onLogout,
        );

      default:
        return MenuPrincipalView(
          user: _currentUser!,
          onStartSoloGame: (int botCount, String difficulty) => _startSolo3DGame(botCount, difficulty),
          onMultiplayer: () => _navigateTo('multiplayer'),
          onSettings: () => _navigateTo('settings'),
        );
    }
  }
}
