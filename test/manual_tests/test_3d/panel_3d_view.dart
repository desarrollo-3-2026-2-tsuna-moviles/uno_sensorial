import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'sensor_3d_controller.dart';

/// Widget que renderiza el bloque 3D (mano de cartas UNO) en la prueba manual
class Panel3DView extends StatelessWidget {
  final Sensor3DController controller;

  const Panel3DView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final vmath.Quaternion q = controller.rotationQuaternion;

        // Determinar cara visible
        final vmath.Vector3 normal = q.rotate(vmath.Vector3(0, 0, 1));
        final bool isFrontVisible = normal.z > 0;

        // Matriz de perspectiva 3D
        final Matrix4 transformMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0018)
          ..multiply(vmath.Matrix4.compose(vmath.Vector3.zero(), q, vmath.Vector3(1.0, 1.0, 1.0)));

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Fondo con patrón de cuadrícula pseudo-AR
            const _BackgroundGrid(),

            // Bloque 3D que representa la Mano de Cartas
            Center(
              child: Transform(
                transform: transformMatrix,
                alignment: Alignment.center,
                child: isFrontVisible
                    ? const _FrontCardHandFace()
                    : const _BackCardHandFace(),
              ),
            ),

            // Superposición de Telemetría e Interfaz de Depuración Completa
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _TelemetryOverlay(controller: controller),
            ),
          ],
        );
      },
    );
  }
}

/// Cara frontal del panel 3D (Mano de Cartas UNO)
class _FrontCardHandFace extends StatelessWidget {
  const _FrontCardHandFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      height: 210,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0055B8), Color(0xFF0088FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(left: 20, top: 25, child: _MiniCard(color: Colors.red, number: '7', angle: -0.15)),
          Positioned(left: 80, top: 15, child: _MiniCard(color: Colors.yellow.shade700, number: '+2', angle: -0.05)),
          Positioned(left: 140, top: 15, child: _MiniCard(color: Colors.green, number: '3', angle: 0.05)),
          Positioned(left: 200, top: 25, child: _MiniCard(color: Colors.blue.shade800, number: '★', angle: 0.15)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'MANO DE CARTAS (PRUEBA 3D)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cara trasera del panel 3D
class _BackCardHandFace extends StatelessWidget {
  const _BackCardHandFace();

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.rotationY(pi),
      alignment: Alignment.center,
      child: Container(
        width: 310,
        height: 210,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFB71C1C), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber, width: 4),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 220,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: const BorderRadius.all(Radius.elliptical(220, 110)),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: const Center(
                  child: Text(
                    'UNO',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 48, fontStyle: FontStyle.italic, letterSpacing: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final Color color;
  final String number;
  final double angle;

  const _MiniCard({required this.color, required this.number, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 70,
        height: 110,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
          ),
        ),
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
      ..color = Colors.white.withValues(alpha: 0.08)
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

/// Panel flotante de telemetría e interactividad con TODOS los botones de control
class _TelemetryOverlay extends StatelessWidget {
  final Sensor3DController controller;

  const _TelemetryOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = controller.currentOrientation == Orientation.landscape;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Fila Superior: Estado e Indicadores
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 8,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    controller.isSimulationMode ? Icons.bug_report : Icons.explore,
                    color: controller.hasMagnetometer ? Colors.greenAccent : Colors.orangeAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    controller.isSimulationMode
                        ? 'Simulación 3D'
                        : '${controller.sensorStatusText} (${isLandscape ? 'Horiz.' : 'Vert.'})',
                    style: TextStyle(
                      color: controller.hasMagnetometer ? Colors.greenAccent : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: controller.toggleInvertPitch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: controller.invertPitch ? Colors.orangeAccent : Colors.white70,
                      side: BorderSide(
                        color: controller.invertPitch ? Colors.orangeAccent : Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      controller.invertPitch ? 'Inv. Pitch: SÍ' : 'Inv. Pitch: NO',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: controller.toggleInvertRoll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: controller.invertRoll ? Colors.orangeAccent : Colors.white70,
                      side: BorderSide(
                        color: controller.invertRoll ? Colors.orangeAccent : Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      controller.invertRoll ? 'Inv. Roll: SÍ' : 'Inv. Roll: NO',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: controller.toggleInvertYaw,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: controller.invertYaw ? Colors.orangeAccent : Colors.white70,
                      side: BorderSide(
                        color: controller.invertYaw ? Colors.orangeAccent : Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      controller.invertYaw ? 'Inv. Yaw: SÍ' : 'Inv. Yaw: NO',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: controller.calibrateCurrentPosition,
                    icon: const Icon(Icons.center_focus_strong, size: 14),
                    label: const Text('Calibrar (0,0)', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Valores de Telemetría Tri-Axial (Pitch, Roll, Yaw)
          Row(
            children: <Widget>[
              Expanded(
                child: _ValueIndicator(
                  label: 'Pitch (Adelante/Atrás)',
                  value: '${controller.pitchDegrees.toStringAsFixed(1)}°',
                ),
              ),
              Expanded(
                child: _ValueIndicator(
                  label: 'Roll (Izquierda/Derecha)',
                  value: '${controller.rollDegrees.toStringAsFixed(1)}°',
                ),
              ),
              Expanded(
                child: _ValueIndicator(
                  label: 'Yaw (Brújula)',
                  value: '${controller.yawDegrees.toStringAsFixed(1)}°',
                ),
              ),
            ],
          ),

          // Controles de Simulación Manual (para Emuladores)
          const Divider(color: Colors.white24, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Simulación Manual (Emulador):',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Switch(
                value: controller.isSimulationMode,
                activeThumbColor: Colors.orangeAccent,
                onChanged: (bool val) => controller.setSimulationMode(val),
              ),
            ],
          ),

          if (controller.isSimulationMode) ...<Widget>[
            Row(
              children: <Widget>[
                const SizedBox(width: 50, child: Text('Pitch:', style: TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(
                  child: Slider(
                    value: controller.pitchDegrees,
                    min: -90,
                    max: 90,
                    onChanged: (double val) => controller.updateSimulationAngles(val, controller.rollDegrees, controller.yawDegrees),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                const SizedBox(width: 50, child: Text('Roll:', style: TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(
                  child: Slider(
                    value: controller.rollDegrees,
                    min: -90,
                    max: 90,
                    onChanged: (double val) => controller.updateSimulationAngles(controller.pitchDegrees, val, controller.yawDegrees),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                const SizedBox(width: 50, child: Text('Yaw:', style: TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(
                  child: Slider(
                    value: controller.yawDegrees,
                    min: -180,
                    max: 180,
                    onChanged: (double val) => controller.updateSimulationAngles(controller.pitchDegrees, controller.rollDegrees, val),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ValueIndicator extends StatelessWidget {
  final String label;
  final String value;

  const _ValueIndicator({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
