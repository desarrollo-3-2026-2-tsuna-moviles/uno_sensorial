import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vmath;

/// Gestos reconocidos durante la partida.
enum GestureType {
  /// RF-20: inclinación/sacudida rápida hacia adelante para lanzar la carta seleccionada.
  throwCard,

  /// RF-21: giro del teléfono alrededor del eje vertical para confirmar una Reversa.
  reverseTwist,

  /// RF-22: sacudida corta hacia arriba para cantar "¡UNO!".
  unoShake,
}

/// Detector de gestos a partir de muestras del acelerómetro y del giroscopio.
///
/// Las muestras llegan en ejes de pantalla de Android: X hacia la derecha,
/// Y hacia el borde superior del teléfono y Z saliendo de la pantalla.
/// Es lógica pura (no accede al hardware), así que se puede probar con datos simulados.
class GestureService {
  GestureService({
    required this.onGesture,
    this.throwThreshold = 4.0,
    this.unoShakeThreshold = 7.0,
    this.twistAngleThreshold = pi / 2,
    this.twistWindow = const Duration(milliseconds: 1500),
    this.cooldown = const Duration(milliseconds: 800),
  });

  final void Function(GestureType gesture) onGesture;

  /// RF-20: velocidad angular hacia adelante (rad/s) que hay que superar para lanzar.
  double throwThreshold;

  /// RF-22: aceleración hacia arriba sin gravedad (m/s²) que hay que superar para cantar UNO.
  double unoShakeThreshold;

  /// RF-21: ángulo (rad) que hay que girar el teléfono para confirmar la Reversa.
  double twistAngleThreshold;

  /// RF-21: tiempo máximo para completar el giro.
  Duration twistWindow;

  /// Tiempo mínimo entre dos detecciones del mismo gesto (evita dobles disparos).
  Duration cooldown;

  /// El giro de Reversa solo se detecta cuando el juego lo está esperando.
  bool _reverseTwistEnabled = false;
  bool get reverseTwistEnabled => _reverseTwistEnabled;
  set reverseTwistEnabled(bool value) {
    if (value != _reverseTwistEnabled) _twistSamples.clear();
    _reverseTwistEnabled = value;
  }

  /// Una sacudida hacia arriba no cuenta si el teléfono está girando rápido
  /// (así un lanzamiento no se confunde con "¡UNO!").
  static const double _maxRotationForShake = 2.0; // rad/s

  /// Filtro paso bajo para estimar la dirección de la gravedad.
  static const double _gravityFilter = 0.1;

  /// `dt` máximo aceptado entre muestras del giroscopio.
  static const double _maxGyroDt = 0.1;

  vmath.Vector3? _gravity;
  double _lastGyroSpeed = 0.0;
  DateTime? _lastGyroTime;
  final List<_TwistSample> _twistSamples = <_TwistSample>[];
  final Map<GestureType, DateTime> _lastFired = <GestureType, DateTime>{};

  /// Procesa una muestra del acelerómetro (m/s², incluye la gravedad).
  void addAccelerometer(vmath.Vector3 acceleration, DateTime timestamp) {
    final vmath.Vector3? gravity = _gravity;
    if (gravity == null || gravity.length2 == 0) {
      _gravity = acceleration.clone();
      return;
    }

    // Aceleración lineal = medida - gravedad estimada, proyectada sobre "arriba".
    final vmath.Vector3 up = gravity.normalized();
    final double upward = (acceleration - gravity).dot(up);

    _gravity = gravity * (1 - _gravityFilter) + acceleration * _gravityFilter;

    if (upward > unoShakeThreshold && _lastGyroSpeed < _maxRotationForShake) {
      _fire(GestureType.unoShake, timestamp);
    }
  }

  /// Procesa una muestra del giroscopio (rad/s, sin bias).
  void addGyroscope(vmath.Vector3 angularVelocity, DateTime timestamp) {
    _lastGyroSpeed = angularVelocity.length;
    final DateTime? last = _lastGyroTime;
    _lastGyroTime = timestamp;

    // RF-20: lanzar = el borde superior se aleja del jugador (giro negativo en X).
    if (-angularVelocity.x > throwThreshold) {
      _fire(GestureType.throwCard, timestamp);
    }

    // RF-21: giro alrededor del eje vertical (la gravedad), en cualquier sentido.
    final vmath.Vector3? gravity = _gravity;
    if (!_reverseTwistEnabled || last == null || gravity == null || gravity.length2 == 0) return;

    final double dt = timestamp.difference(last).inMicroseconds / 1e6;
    if (dt <= 0 || dt > _maxGyroDt) return;

    final double verticalRate = angularVelocity.dot(gravity.normalized());
    _twistSamples.add(_TwistSample(timestamp, verticalRate * dt));
    _twistSamples.removeWhere((_TwistSample s) => timestamp.difference(s.time) > twistWindow);

    final double totalAngle = _twistSamples.fold(0.0, (double sum, _TwistSample s) => sum + s.angle);
    if (totalAngle.abs() >= twistAngleThreshold) {
      _twistSamples.clear();
      _fire(GestureType.reverseTwist, timestamp);
    }
  }

  void _fire(GestureType gesture, DateTime timestamp) {
    final DateTime? last = _lastFired[gesture];
    if (last != null && timestamp.difference(last) < cooldown) return;
    _lastFired[gesture] = timestamp;
    onGesture(gesture);
  }
}

class _TwistSample {
  const _TwistSample(this.time, this.angle);
  final DateTime time;
  final double angle;
}
