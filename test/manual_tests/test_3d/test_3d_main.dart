import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'panel_3d_view.dart';
import 'sensor_3d_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const Test3DApp());
}

class Test3DApp extends StatelessWidget {
  const Test3DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prueba Manual 3D - UNO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const Test3DScreen(),
    );
  }
}

class Test3DScreen extends StatefulWidget {
  const Test3DScreen({super.key});

  @override
  State<Test3DScreen> createState() => _Test3DScreenState();
}

class _Test3DScreenState extends State<Test3DScreen> {
  late final Sensor3DController _sensorController;

  @override
  void initState() {
    super.initState();
    _sensorController = Sensor3DController();
  }

  @override
  void dispose() {
    _sensorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba Manual 3D'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            _sensorController.updateOrientation(orientation);
            return Panel3DView(controller: _sensorController);
          },
        ),
      ),
    );
  }
}
