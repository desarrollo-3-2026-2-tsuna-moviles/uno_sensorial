import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'viewmodels/game_3d_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();
    _sensorViewModel = SensorViewModel();
  }

  @override
  void dispose() {
    _sensorViewModel.dispose();
    super.dispose();
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

  void _startSolo3DGame(int botCount) {
    final Game3DViewModel game3DVM = Game3DViewModel();
    game3DVM.setupSoloGame(botCount: botCount, difficulty: 'Normal');

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
          onStartSoloGame: (int botCount) => _startSolo3DGame(botCount),
          onMultiplayer: () => _navigateTo('multiplayer'),
          onSettings: () => _navigateTo('settings'),
        );

      case 'multiplayer':
        return MultiplayerView(
          onCreateRoom: (String code) {
            setState(() {
              _activeRoomCode = code;
              _isRoomHost = true;
              _currentScreen = 'waiting';
            });
          },
          onJoinRoom: (String code) {
            setState(() {
              _activeRoomCode = code;
              _isRoomHost = false;
              _currentScreen = 'waiting';
            });
          },
          onBack: () => _navigateTo('menu'),
        );

      case 'waiting':
        return WaitingRoomView(
          user: _currentUser!,
          roomCode: _activeRoomCode,
          isHost: _isRoomHost,
          onStartGame: () => _startSolo3DGame(2),
          onBack: () => _navigateTo('multiplayer'),
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
          onStartSoloGame: (int botCount) => _startSolo3DGame(botCount),
          onMultiplayer: () => _navigateTo('multiplayer'),
          onSettings: () => _navigateTo('settings'),
        );
    }
  }
}
