import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_game/services/lan_network_service.dart';
import 'package:uno_game/viewmodels/lobby_viewmodel.dart';
import 'package:uno_game/viewmodels/sensor_viewmodel.dart';
import 'package:uno_game/views/lobby_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const TestMultiplayerApp());
}

class TestMultiplayerApp extends StatefulWidget {
  const TestMultiplayerApp({super.key});

  @override
  State<TestMultiplayerApp> createState() => _TestMultiplayerAppState();
}

class _TestMultiplayerAppState extends State<TestMultiplayerApp> {
  late final LanNetworkService _netService;
  late final LobbyViewModel _lobbyViewModel;
  late final SensorViewModel _sensorViewModel;

  @override
  void initState() {
    super.initState();
    _netService = LanNetworkService();
    _lobbyViewModel = LobbyViewModel(netService: _netService);
    _sensorViewModel = SensorViewModel();
  }

  @override
  void dispose() {
    _sensorViewModel.dispose();
    _lobbyViewModel.dispose();
    _netService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prueba Multijugador LAN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: LobbyView(
        lobbyViewModel: _lobbyViewModel,
        sensorViewModel: _sensorViewModel,
      ),
    );
  }
}
