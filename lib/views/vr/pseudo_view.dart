import 'dart:math';
import 'dart:ui';

/// Punto de la escena ya proyectado a pantalla.
class ScenePoint {
  const ScenePoint({required this.x, required this.y, required this.forward, required this.visible});

  final double x;
  final double y;

  /// Distancia hacia delante respecto a la mirada; sirve para escalar y ordenar.
  final double forward;
  final bool visible;
}

/// Vista en primera persona "de mentira": el jugador está sentado en el borde de la
/// mesa y gira la cabeza (yaw/pitch). No hay cámara 3D; cada punto del plano de la mesa
/// se coloca con una sola división de perspectiva.
///
/// Mundo: el centro de la mesa es el origen y el asiento local está en +Z.
class PseudoView {
  PseudoView({
    required this.size,
    required this.yaw,
    required this.pitch,
    required this.tableRadius,
  });

  /// Campo de visión vertical (rad).
  static const double fov = 0.94;

  /// No hay nadie detrás del jugador: la cabeza no pasa de ±100° ni ±30° en vertical.
  static const double maxYaw = 100 * pi / 180;
  static const double maxPitch = 30 * pi / 180;

  final Size size;
  final double yaw;
  final double pitch;
  final double tableRadius;

  late final double focal = (size.height / 2) / tan(fov / 2);
  late final double viewerDistance = tableRadius * 1.5;
  late final double eyeHeight = tableRadius * 0.35;
  late final double horizon = size.height * 0.28 + focal * tan(pitch);
  late final double near = tableRadius * 0.08;

  /// Factor de tamaño de la interfaz según el alto de pantalla (diseñada para 360).
  late final double ui = size.height / 360;

  static double clampYaw(double v) => v.clamp(-maxYaw, maxYaw);
  static double clampPitch(double v) => v.clamp(-maxPitch, maxPitch);

  /// Coordenadas relativas al espectador: `lateral` a su derecha, `forward` hacia donde mira.
  ({double lateral, double forward}) toLocal(double wx, double wz) {
    final double dx = wx;
    final double dz = wz - viewerDistance;
    return (
      lateral: dx * cos(yaw) + dz * sin(yaw),
      forward: dx * sin(yaw) - dz * cos(yaw),
    );
  }

  Offset projectLocal(double lateral, double forward, double height) {
    final double k = focal / forward;
    return Offset(size.width / 2 + lateral * k, horizon + (eyeHeight - height) * k);
  }

  ScenePoint project(double wx, double wz, [double height = 0]) {
    final l = toLocal(wx, wz);
    final double f = max(l.forward, near);
    final Offset p = projectLocal(l.lateral, f, height);
    return ScenePoint(x: p.dx, y: p.dy, forward: f, visible: l.forward > near);
  }

  /// Escala en pantalla de un widget que mide `worldScale` unidades de mesa por píxel.
  double screenScale(double forward, double worldScale) =>
      (worldScale * focal / forward).clamp(0.25, 1.7);
}
