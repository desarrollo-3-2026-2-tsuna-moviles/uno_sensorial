import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/player_model.dart';
import '../viewmodels/game_3d_viewmodel.dart';
import '../viewmodels/sensor_viewmodel.dart';
import 'vr/pseudo_view.dart';
import 'widgets/game_hud_overlay.dart';
import 'widgets/vr_table_scene.dart';

/// Vista unificada del escenario 3D (Solo / Multijugador LAN) en primera persona.
/// El jugador está sentado a la mesa con su mano delante y los rivales a su alrededor.
///
/// Dos modos según si la mano está seleccionada:
/// 1. Modo Vista (mano NO seleccionada): el sensor gira la cabeza (yaw/pitch).
/// 2. Modo Mano (mano SELECCIONADA): la vista se congela y el sensor gira la mano
///    libremente (a futuro, para mostrar las cartas).
///
/// También se puede controlar arrastrando el mouse para pruebas en PC.
class Game3DTableView extends StatefulWidget {
  final Game3DViewModel game3DViewModel;
  final SensorViewModel sensorViewModel;
  final VoidCallback onExit;

  const Game3DTableView({
    super.key,
    required this.game3DViewModel,
    required this.sensorViewModel,
    required this.onExit,
  });

  @override
  State<Game3DTableView> createState() => _Game3DTableViewState();
}

class _Game3DTableViewState extends State<Game3DTableView> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationAnimationController;
  bool _isHandSelected = false;

  // Acumuladores del mouse (grados). En modo Vista: dx -> yaw, dy -> pitch.
  // En modo Mano: dx -> roll, dy -> pitch.
  double _mousePitchDeg = 0.0;
  double _mouseRollDeg = 0.0;
  double _mouseYawDeg = 0.0;

  // Continuidad al cambiar de modo
  double _yawOffset = 0.0;
  double _pitchOffset = 0.0;
  double _frozenYaw = 0.0;
  double _frozenPitch = 0.0;
  vmath.Quaternion _handReference = vmath.Quaternion.identity();

  @override
  void initState() {
    super.initState();
    // Forzar orientación horizontal durante la partida
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _rotationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationAnimationController.dispose();
    // Restablecer orientaciones adaptativas al salir
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  vmath.Quaternion _conjugate(vmath.Quaternion q) => vmath.Quaternion(-q.x, -q.y, -q.z, q.w);

  /// Dirección de la mirada: sensor + desfase acumulado, o la congelada en Modo Mano.
  ({double yaw, double pitch}) _currentLook() {
    if (_isHandSelected) return (yaw: _frozenYaw, pitch: _frozenPitch);
    final SensorViewModel sensor = widget.sensorViewModel;
    return (
      yaw: PseudoView.clampYaw(sensor.yaw + _yawOffset),
      pitch: PseudoView.clampPitch(sensor.pitch + _pitchOffset),
    );
  }

  void _toggleHandSelection() {
    setState(() {
      final SensorViewModel sensor = widget.sensorViewModel;
      if (!_isHandSelected) {
        final look = _currentLook();
        _frozenYaw = look.yaw;
        _frozenPitch = look.pitch;
        _handReference = _conjugate(sensor.rotationQuaternion);
        _isHandSelected = true;
      } else {
        _yawOffset = _frozenYaw - sensor.yaw;
        _pitchOffset = _frozenPitch - sensor.pitch;
        _isHandSelected = false;
      }
    });
  }

  void _onMousePanUpdate(DragUpdateDetails details) {
    setState(() {
      _mousePitchDeg += details.delta.dy * 0.35;
      if (_isHandSelected) {
        _mouseRollDeg += details.delta.dx * 0.35;
      } else {
        _mouseYawDeg = (_mouseYawDeg + details.delta.dx * 0.35).clamp(-100.0, 100.0);
        _mousePitchDeg = _mousePitchDeg.clamp(-80.0, 80.0);
      }
      widget.sensorViewModel.updateSimulationAngles(_mousePitchDeg, _mouseRollDeg, _mouseYawDeg);
    });
  }

  void _resetMouseRotation() {
    setState(() {
      _mousePitchDeg = 0.0;
      _mouseRollDeg = 0.0;
      _mouseYawDeg = 0.0;
      _yawOffset = 0.0;
      _pitchOffset = 0.0;
      _frozenYaw = 0.0;
      _frozenPitch = 0.0;
      widget.sensorViewModel.updateSimulationAngles(0.0, 0.0, 0.0);
      _handReference = _conjugate(widget.sensorViewModel.rotationQuaternion);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: _onMousePanUpdate,
        onDoubleTap: _resetMouseRotation,
        child: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[widget.game3DViewModel, widget.sensorViewModel]),
          builder: (BuildContext context, Widget? child) {
            final List<PlayerModel> players = widget.game3DViewModel.players;
            final List<PlayerModel> seated = players.isNotEmpty
                ? players
                : <PlayerModel>[PlayerModel(id: 'me', name: 'Tú', seatIndex: 0)];

            final look = _currentLook();
            final vmath.Quaternion handQ = _isHandSelected
                ? _handReference * widget.sensorViewModel.rotationQuaternion
                : vmath.Quaternion.identity();

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                VrTableScene(
                  players: seated,
                  currentTurnSeatIndex: widget.game3DViewModel.currentTurnIndex,
                  topCard: widget.game3DViewModel.topCard,
                  rotationController: _rotationAnimationController,
                  yaw: look.yaw,
                  pitch: look.pitch,
                  handRotation: handQ,
                  isHandSelected: _isHandSelected,
                  onPlayCard: (_) {},
                ),

                // Selector de modo: mover la vista o mover la mano
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _ModeToggle(isHandSelected: _isHandSelected, onTap: _toggleHandSelection),
                ),

                GameHudOverlay(
                  game3DViewModel: widget.game3DViewModel,
                  onExit: widget.onExit,
                  onResetMouseRotation: _resetMouseRotation,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isHandSelected;
  final VoidCallback onTap;

  const _ModeToggle({required this.isHandSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color fg = isHandSelected ? Colors.black : Colors.amberAccent;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isHandSelected ? const Color(0xFFFFD700) : Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isHandSelected ? Colors.white : Colors.amberAccent, width: isHandSelected ? 2 : 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(isHandSelected ? Icons.pan_tool : Icons.remove_red_eye, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                isHandSelected ? 'MODO MANO (el sensor gira las cartas)' : 'MODO VISTA (el sensor gira la cabeza)',
                style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
