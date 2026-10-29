import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/login_view.dart';
import 'views/menu_view.dart';
import 'views/multiplayer_view.dart';
import 'views/settings_view.dart';
import 'views/waiting_room_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Adaptar orientaciones
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const UnoGameApp());
}

/// Aplicación Principal que conecta todas las pantallas de menús de Figma
class UnoGameApp extends StatelessWidget {
  const UnoGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNO - Menú Principal y Vistas Figma',
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
  String _currentScreen = 'login'; // 'login', 'menu', 'multiplayer', 'waiting', 'settings'
  String _activeRoomCode = 'ABCD12';
  bool _isRoomHost = true;

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

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _currentScreen == 'login') {
      return LoginView(onLogin: _onLogin);
    }

    switch (_currentScreen) {
      case 'menu':
        return MenuPrincipalView(
          user: _currentUser!,
          onSolo: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Modo Jugar Solo (IA) seleccionado')),
            );
          },
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
          onStartGame: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Iniciando Partida')),
            );
          },
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
          onSolo: () {},
          onMultiplayer: () => _navigateTo('multiplayer'),
          onSettings: () => _navigateTo('settings'),
        );
    }
  }
}
