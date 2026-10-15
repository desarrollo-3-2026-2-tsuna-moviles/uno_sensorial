import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/lan_network_service.dart';
import 'viewmodels/lobby_viewmodel.dart';
import 'viewmodels/sensor_viewmodel.dart';
import 'views/lobby_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Habilitar orientaciones adaptativas
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const UnoGameApp());
}

/// Aplicación Principal basada en Arquitectura MVVM (Model-View-ViewModel)
class UnoGameApp extends StatefulWidget {
  const UnoGameApp({super.key});

  @override
  State<UnoGameApp> createState() => _UnoGameAppState();
}

class _UnoGameAppState extends State<UnoGameApp> {
  late final LanNetworkService _netService;
  late final LobbyViewModel _lobbyViewModel;
  late final SensorViewModel _sensorViewModel;

  @override
  void initState() {
    super.initState();
    // Capa de Servicios y ViewModels MVVM
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
      title: 'UNO Juego 3D - MVVM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: LobbyView(
        lobbyViewModel: _lobbyViewModel,
        sensorViewModel: _sensorViewModel,
      ),
    );
  }
}
