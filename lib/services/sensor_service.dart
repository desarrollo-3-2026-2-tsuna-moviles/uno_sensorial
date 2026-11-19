import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

/// Muestra de un sensor en ejes de pantalla (X derecha, Y borde superior, Z saliendo de la pantalla).
class SensorSample {
  const SensorSample(this.value, this.timestamp);
  final vmath.Vector3 value;
  final DateTime timestamp;
}

/// Servicio de capa Data/Service que gestiona el hardware de acelerómetro, magnetómetro y giroscopio.
///
/// RF-17: integración de `sensors_plus` (acelerómetro, magnetómetro y giroscopio).
/// RF-18: filtro complementario para suavizar la orientación:
///   - El giroscopio aporta la rotación rápida (se integra con el `dt` real entre eventos).
///   - La gravedad (acelerómetro) corrige poco a poco la inclinación, en los 360°.
///   - La brújula (magnetómetro) corrige poco a poco el yaw cuando la carta está boca arriba.
///   - Si el dispositivo no tiene giroscopio, la corrección usa [smoothingFactor] (más rápida).
class SensorService {
  /// Frecuencia de muestreo de los sensores (~50 Hz). El valor por defecto de
  /// `sensors_plus` es 200 ms (5 Hz), demasiado lento para una vista 3D fluida.
  static const Duration samplingPeriod = SensorInterval.gameInterval;

  /// Peso de la corrección acelerómetro/magnetómetro por evento cuando hay giroscopio.
  /// Valores bajos = más suave pero corrige la deriva más despacio.
  static const double gyroCorrectionFactor = 0.03;

  /// Velocidad angular mínima (rad/s) para integrar el giroscopio (zona muerta anti-ruido).
  /// 0.03 rad/s ≈ 1.7°/s: filtra el ruido de giroscopios baratos sin perder movimientos reales.
  static const double _gyroDeadZone = 0.03;

  /// Si el celular gira más lento que esto (rad/s) y la gravedad es estable,
  /// se considera quieto y se aprende el desvío (bias) del giroscopio.
  static const double _stillGyroThreshold = 0.06;

  /// Margen (m/s²) respecto a la gravedad para considerar el celular quieto.
  static const double _stillAccTolerance = 0.4;

  /// Velocidad de aprendizaje del bias del giroscopio (por evento).
  static const double _biasLearningRate = 0.01;

  static const double _gravity = 9.81;

  /// `dt` máximo aceptado entre eventos del giroscopio (evita saltos tras pausas).
  static const double _maxGyroDt = 0.1;

  /// Peso de la corrección del yaw por evento cuando hay giroscopio (brújula o
  /// re-centrado). Muy bajo (~4 s) para no transmitir el ruido del magnetómetro.
  static const double _yawCorrectionFactor = 0.01;

  /// La brújula solo corrige el yaw si la pantalla mira hacia arriba al menos
  /// este valor (componente Z de la gravedad normalizada, 0.5 ≈ 60° de inclinación).
  static const double _minUpForCompass = 0.5;

  StreamSubscription<AccelerometerEvent>? _accSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<MagnetometerEvent>? _magSubscription;

  // Configuración: se lee en cada cálculo, por lo que los cambios aplican en tiempo real.
  Orientation orientation = Orientation.portrait;
  bool invertPitch = true;
  bool invertRoll = false;
  bool invertYaw = false;
  /// Brújula apagada por defecto: en muchos celulares el magnetómetro está mal
  /// calibrado y hace girar la carta sola. Sin brújula, el yaw lo lleva el giroscopio.
  bool enableCompass = false;

  /// Si es `false`, se ignora el giroscopio y la orientación sale solo del
  /// acelerómetro suavizado con SLERP (sin deriva y sin ruido del giroscopio).
  bool useGyroscope = true;

  /// Suavizado SLERP por evento cuando no hay giroscopio (~50 Hz).
  /// Valores bajos = menos temblor pero más retraso.
  double smoothingFactor = 0.06;

  vmath.Vector3 latestAcc = vmath.Vector3(0, 0.98, 0);
  vmath.Vector3 latestMag = vmath.Vector3(0, 1, 0);
  vmath.Quaternion currentQuaternion = vmath.Quaternion.identity();

  bool hasMagnetometer = false;
  bool hasGyroscope = false;
  String statusText = 'Iniciando sensores...';

  DateTime? _lastGyroTimestamp;

  /// Desvío constante del giroscopio (rad/s, ejes del sensor) aprendido estando quieto.
  final vmath.Vector3 _gyroBias = vmath.Vector3.zero();

  // Lecturas crudas para otros consumidores (p. ej. detección de gestos, RF-20 a RF-22).
  final StreamController<SensorSample> _accelerometerSamples = StreamController<SensorSample>.broadcast();
  final StreamController<SensorSample> _gyroscopeSamples = StreamController<SensorSample>.broadcast();

  /// Acelerómetro (m/s², incluye gravedad) en ejes de pantalla.
  Stream<SensorSample> get accelerometerSamples => _accelerometerSamples.stream;

  /// Giroscopio (rad/s, sin bias) en ejes de pantalla.
  Stream<SensorSample> get gyroscopeSamples => _gyroscopeSamples.stream;

  /// Última velocidad angular medida (rad/s, sin bias): indica si el celular se mueve.
  double _gyroSpeed = 0.0;

  /// Orientación que se muestra: [currentQuaternion] con suavizado adaptativo.
  vmath.Quaternion _displayQuaternion = vmath.Quaternion.identity();

  // Corrección más rápida en reposo (la carta vuelve a su sitio al dejarla en la mesa).
  static const double _stillTiltFactor = 0.08;
  static const double _stillYawFactor = 0.03;

  // Suavizado de salida: fuerte en reposo (sin temblor), nulo al mover (sin retraso).
  static const double _minDisplayAlpha = 0.15;
  static const double _fullResponseSpeed = 1.0; // rad/s

  void listen({
    required void Function(vmath.Quaternion q) onSensorUpdate,
    required void Function(String status) onStatusUpdate,
  }) {
    void setStatus(String status) {
      if (statusText == status) return;
      statusText = status;
      onStatusUpdate(statusText);
    }

    // Acelerómetro: corrige la inclinación (y el yaw con la brújula).
    _accSubscription = accelerometerEventStream(samplingPeriod: samplingPeriod).listen(
      (AccelerometerEvent event) {
        latestAcc = _remapToScreen(event.x, event.y, event.z);
        _accelerometerSamples.add(SensorSample(latestAcc.clone(), event.timestamp));
        _applyAbsoluteCorrection();
        onSensorUpdate(_smoothedOutput());
      },
      onError: (dynamic error) => setStatus('Error en acelerómetro'),
    );

    // Magnetómetro: solo guarda la lectura; la corrección se aplica con el acelerómetro.
    _magSubscription = magnetometerEventStream(samplingPeriod: samplingPeriod).listen(
      (MagnetometerEvent event) {
        hasMagnetometer = true;
        latestMag = _remapToScreen(event.x, event.y, event.z);
        setStatus('Brújula Compensada (OK)');
      },
      onError: (dynamic error) {
        hasMagnetometer = false;
        setStatus('Sin Magnetómetro (Solo Acelerómetro)');
      },
    );

    // Giroscopio: integra la velocidad angular con el dt real del evento.
    _gyroSubscription = gyroscopeEventStream(samplingPeriod: samplingPeriod).listen(
      (GyroscopeEvent event) {
        hasGyroscope = true;
        if (!useGyroscope) {
          _lastGyroTimestamp = null;
          _gyroSpeed = 0.0;
          return;
        }

        final DateTime? last = _lastGyroTimestamp;
        _lastGyroTimestamp = event.timestamp;
        if (last == null) return;

        final double dt = event.timestamp.difference(last).inMicroseconds / 1e6;
        if (dt <= 0 || dt > _maxGyroDt) return;

        // Quitar el desvío constante del giroscopio (y aprenderlo si el celular está quieto).
        final vmath.Vector3 raw = vmath.Vector3(event.x, event.y, event.z);
        _updateGyroBias(raw);
        final vmath.Vector3 corrected = raw - _gyroBias;
        _gyroSpeed = corrected.length;
        _gyroscopeSamples.add(
          SensorSample(_remapToScreen(corrected.x, corrected.y, corrected.z), event.timestamp),
        );

        final vmath.Vector3 omega = _gyroToModelAxes(corrected.x, corrected.y, corrected.z);
        final double speed = omega.length;
        if (speed < _gyroDeadZone) return;

        final vmath.Quaternion delta = vmath.Quaternion.axisAngle(omega.normalized(), speed * dt);
        // La carta es una "ventana fija": gira al revés que el celular, en ejes de pantalla.
        currentQuaternion = delta * currentQuaternion;
        currentQuaternion.normalize();
        onSensorUpdate(_smoothedOutput());
      },
      onError: (dynamic error) => hasGyroscope = false,
    );
  }

  /// Pone a 0 el yaw actual (giro tipo volante), sin tocar la inclinación.
  /// Se usa al calibrar para que el re-centrado lento no deje la carta torcida.
  void resetYaw() {
    final double yaw = _currentYaw();
    // Multiplicar a la derecha por Rz(δ) SUMA δ al yaw, así que se resta el yaw actual.
    currentQuaternion = currentQuaternion * vmath.Quaternion.axisAngle(vmath.Vector3(0, 0, 1), -yaw);
    currentQuaternion.normalize();
    _displayQuaternion = currentQuaternion.clone();
  }

  /// Devuelve la orientación a mostrar con suavizado adaptativo: casi sin filtro
  /// cuando el celular gira rápido y con filtro fuerte cuando está quieto.
  vmath.Quaternion _smoothedOutput() {
    final bool gyroActive = hasGyroscope && useGyroscope;
    final double alpha = gyroActive
        ? (_gyroSpeed / _fullResponseSpeed).clamp(_minDisplayAlpha, 1.0)
        : 1.0; // Sin giroscopio ya se suaviza con [smoothingFactor].
    _displayQuaternion = _slerp(_displayQuaternion, currentQuaternion, alpha);
    return _displayQuaternion.clone();
  }

  /// Rotación mínima que lleva [from] a [to]. A diferencia de
  /// `Quaternion.fromTwoVectors`, no ignora diferencias pequeñas (< ~2°).
  vmath.Quaternion _rotationBetween(vmath.Vector3 from, vmath.Vector3 to) {
    final vmath.Vector3 a = from.normalized();
    final vmath.Vector3 b = to.normalized();
    final vmath.Vector3 axis = a.cross(b);
    final double sinAngle = axis.length;
    final double cosAngle = a.dot(b);

    if (sinAngle < 1e-9) {
      if (cosAngle > 0) return vmath.Quaternion.identity();
      // Vectores opuestos: cualquier eje perpendicular sirve.
      final vmath.Vector3 helper = a.x.abs() < 0.9 ? vmath.Vector3(1, 0, 0) : vmath.Vector3(0, 1, 0);
      return vmath.Quaternion.axisAngle(a.cross(helper)..normalize(), pi);
    }
    return vmath.Quaternion.axisAngle(axis, atan2(sinAngle, cosAngle));
  }

  /// Aprende poco a poco el desvío del giroscopio mientras el celular está quieto
  /// (gira muy despacio y el acelerómetro solo mide la gravedad).
  void _updateGyroBias(vmath.Vector3 raw) {
    final bool gyroStill = (raw - _gyroBias).length < _stillGyroThreshold;
    final bool accStill = (latestAcc.length - _gravity).abs() < _stillAccTolerance;
    if (gyroStill && accStill) {
      _gyroBias.add((raw - _gyroBias)..scale(_biasLearningRate));
    }
  }

  /// Convierte los ejes del sensor a los ejes de la pantalla según la orientación actual.
  vmath.Vector3 _remapToScreen(double x, double y, double z) {
    if (orientation == Orientation.portrait) {
      return vmath.Vector3(x, y, z);
    }
    return vmath.Vector3(-y, x, z);
  }

  /// Signos de cada eje del modelo. Con los valores por defecto (Inv. Pitch SÍ,
  /// Roll NO, Yaw NO) la carta se comporta como una "ventana fija en el mundo".
  double get _pitchSign => invertPitch ? -1.0 : 1.0;
  double get _rollSign => invertRoll ? -1.0 : 1.0;
  double get _yawSign => invertYaw ? -1.0 : 1.0;

  /// Lleva la velocidad angular del giroscopio a los ejes de pantalla del modelo 3D
  /// (Flutter: X derecha, Y abajo, Z hacia dentro), con la misma convención que
  /// la corrección por gravedad y brújula para que no se contradigan.
  vmath.Vector3 _gyroToModelAxes(double gx, double gy, double gz) {
    final vmath.Vector3 w = _remapToScreen(gx, gy, gz);
    return vmath.Vector3(_pitchSign * w.x, _rollSign * w.y, _yawSign * w.z);
  }

  /// Hacia dónde debería apuntar la cara de la carta (su eje Z) según la gravedad.
  /// Con el celular boca arriba es (0, 0, 1) (cara visible); boca abajo, (0, 0, -1).
  vmath.Vector3? _targetNormalFromGravity() {
    if (latestAcc.length2 == 0) return null;
    final vmath.Vector3 a = latestAcc.normalized();
    return vmath.Vector3(-_rollSign * a.x, -_pitchSign * a.y, a.z);
  }

  /// Corrige la orientación con la gravedad (inclinación) y la brújula (yaw).
  ///
  /// En vez de convertir la gravedad en ángulos (que solo llegan a ±90°), compara
  /// la dirección de la gravedad medida con la que predice la orientación actual
  /// y aplica una pequeña rotación correctiva. Así funciona en los 360°,
  /// incluido voltear la carta para ver el reverso.
  void _applyAbsoluteCorrection() {
    final bool gyroActive = hasGyroscope && useGyroscope;
    final bool isStill = gyroActive &&
        _gyroSpeed < _stillGyroThreshold &&
        (latestAcc.length - _gravity).abs() < _stillAccTolerance;
    final double factor = gyroActive
        ? (isStill ? _stillTiltFactor : gyroCorrectionFactor)
        : smoothingFactor;

    // 1) Inclinación: llevar la cara actual de la carta hacia la que indica la gravedad.
    final vmath.Vector3? targetNormal = _targetNormalFromGravity();
    if (targetNormal == null) return;

    // OJO: en vector_math, `q.rotated(v)` aplica la rotación INVERSA (conj(q)·v·q).
    // Para obtener la rotación normal (la que se dibuja en pantalla) se usa el conjugado.
    final vmath.Vector3 currentNormal = currentQuaternion.conjugated().rotated(vmath.Vector3(0, 0, 1));
    final vmath.Quaternion tiltError = _rotationBetween(currentNormal, targetNormal);
    final vmath.Quaternion tiltStep = _slerp(vmath.Quaternion.identity(), tiltError, factor);
    currentQuaternion = tiltStep * currentQuaternion;
    currentQuaternion.normalize();

    // 2) Yaw: solo si la pantalla mira hacia arriba (cerca de vertical la brújula no es fiable).
    if (targetNormal.z < _minUpForCompass) return;

    // Con brújula: el yaw tiende al rumbo magnético.
    // Sin brújula: el yaw se re-centra muy despacio a 0 (el giro de muñeca que se
    // cuela al inclinar el celular no deja la carta torcida para siempre).
    final bool compassActive = enableCompass && hasMagnetometer;
    final double? compassYaw = _compassYaw();
    if (compassActive && compassYaw == null) return; // Lectura no fiable: no corregir.
    final double targetYaw = compassYaw ?? 0.0;
    final double yawFactor = gyroActive
        ? (isStill ? _stillYawFactor : _yawCorrectionFactor)
        : factor;
    final double yawError = _wrapAngle(targetYaw - _currentYaw());
    // Girar sobre el propio eje Z de la carta cambia el yaw sin tocar la inclinación.
    // Multiplicar a la derecha por Rz(δ) SUMA δ al yaw: δ lleva el mismo signo que el error.
    final vmath.Quaternion yawStep = vmath.Quaternion.axisAngle(vmath.Vector3(0, 0, 1), yawError * yawFactor);
    currentQuaternion = currentQuaternion * yawStep;
    currentQuaternion.normalize();
  }

  /// Yaw de la brújula compensado por inclinación, en la convención del modelo.
  /// Devuelve `null` si no hay brújula (en ese caso el yaw tiende a 0).
  ///
  /// Mide hacia dónde apunta el borde superior del celular (eje Y) visto desde
  /// arriba, igual que `SensorManager.getOrientation` de Android:
  /// Este = magnético × arriba, Norte = arriba × Este.
  double? _compassYaw() {
    if (!enableCompass || !hasMagnetometer || latestMag.length2 == 0) return null;

    final vmath.Vector3 up = latestAcc.normalized();
    final vmath.Vector3 east = latestMag.cross(up);
    if (east.length < 0.1 * latestMag.length) return null; // Campo casi vertical: no fiable.
    east.normalize();
    final vmath.Vector3 north = up.cross(east);

    // El azimut de Android crece en sentido horario; el yaw del modelo, al revés.
    final double azimuth = atan2(east.y, north.y);
    return -_yawSign * azimuth;
  }

  /// Yaw de la orientación actual, medido igual que [_compassYaw] (hacia dónde
  /// apunta el borde superior del celular visto desde arriba), para que ambos
  /// ángulos sean comparables aunque la carta esté inclinada en pitch y roll.
  double _currentYaw() {
    final vmath.Quaternion q = currentQuaternion;
    // Fila 1 de la matriz de rotación: (R10, R11).
    return atan2(2 * (q.x * q.y + q.w * q.z), 1 - 2 * (q.x * q.x + q.z * q.z));
  }

  /// Normaliza un ángulo al rango [-π, π] para corregir siempre por el camino corto.
  double _wrapAngle(double angle) {
    double a = angle;
    while (a > pi) {
      a -= 2 * pi;
    }
    while (a < -pi) {
      a += 2 * pi;
    }
    return a;
  }

  vmath.Quaternion _slerp(vmath.Quaternion q1, vmath.Quaternion q2, double t) {
    double dot = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w;

    vmath.Quaternion targetQ2 = q2;
    if (dot < 0.0) {
      dot = -dot;
      targetQ2 = vmath.Quaternion(-q2.x, -q2.y, -q2.z, -q2.w);
    }

    if (dot > 0.9995) {
      final vmath.Quaternion result = vmath.Quaternion(
        q1.x + t * (targetQ2.x - q1.x),
        q1.y + t * (targetQ2.y - q1.y),
        q1.z + t * (targetQ2.z - q1.z),
        q1.w + t * (targetQ2.w - q1.w),
      );
      result.normalize();
      return result;
    }

    final double theta0 = acos(dot.clamp(-1.0, 1.0));
    final double theta = theta0 * t;
    final double sinTheta = sin(theta);
    final double sinTheta0 = sin(theta0);

    final double s0 = cos(theta) - dot * sinTheta / sinTheta0;
    final double s1 = sinTheta / sinTheta0;

    final vmath.Quaternion result = vmath.Quaternion(
      (s0 * q1.x) + (s1 * targetQ2.x),
      (s0 * q1.y) + (s1 * targetQ2.y),
      (s0 * q1.z) + (s1 * targetQ2.z),
      (s0 * q1.w) + (s1 * targetQ2.w),
    );
    result.normalize();
    return result;
  }

  void dispose() {
    _accSubscription?.cancel();
    _gyroSubscription?.cancel();
    _magSubscription?.cancel();
    _accelerometerSamples.close();
    _gyroscopeSamples.close();
  }
}
