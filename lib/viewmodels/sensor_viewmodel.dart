import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../services/sensor_service.dart';

/// ViewModel que expone el estado de los sensores 3D a las vistas (Views)
class SensorViewModel extends ChangeNotifier {
  final SensorService _service = SensorService();

  vmath.Quaternion _currentQuaternion = vmath.Quaternion.identity();
  vmath.Quaternion _calibrationOffset = vmath.Quaternion.identity();

  bool _isSimulationMode = false;
  double _simulatedPitch = 0.0;
  double _simulatedRoll = 0.0;
  double _simulatedYaw = 0.0;

  String _statusText = 'Iniciando...';

  SensorViewModel() {
    _service.listen(
      onSensorUpdate: (vmath.Quaternion q) {
        if (!_isSimulationMode) {
          _currentQuaternion = q;
          notifyListeners();
        }
      },
      onStatusUpdate: (String status) {
        _statusText = status;
        notifyListeners();
      },
    );
  }

  vmath.Quaternion get rotationQuaternion {
    if (_isSimulationMode) {
      final double px = invertPitch ? -_simulatedPitch : _simulatedPitch;
      final double ry = invertRoll ? -_simulatedRoll : _simulatedRoll;
      final double yz = invertYaw ? -_simulatedYaw : _simulatedYaw;

      final vmath.Quaternion qX = vmath.Quaternion.axisAngle(vmath.Vector3(1, 0, 0), px);
      final vmath.Quaternion qY = vmath.Quaternion.axisAngle(vmath.Vector3(0, 1, 0), yz);
      final vmath.Quaternion qZ = vmath.Quaternion.axisAngle(vmath.Vector3(0, 0, 1), ry);
      return qY * qX * qZ;
    }

    // La calibración se aplica a la derecha (en los ejes propios del celular).
    // Si se aplicara a la izquierda, la dirección de la brújula guardada al calibrar
    // torcería el eje del pitch y la carta se voltearía en diagonal o de lado.
    final vmath.Quaternion result = _currentQuaternion * _calibrationOffset;
    result.normalize();
    return result;
  }

  double get pitchDegrees => pitch * 180 / pi;
  double get rollDegrees => roll * 180 / pi;
  double get yawDegrees => yaw * 180 / pi;

  double get pitch {
    final vmath.Quaternion q = rotationQuaternion;
    final double sinp = 2 * (q.w * q.x - q.y * q.z);
    if (sinp.abs() >= 1) return sinp.sign * pi / 2;
    return asin(sinp);
  }

  double get roll {
    final vmath.Quaternion q = rotationQuaternion;
    final double sinrCosp = 2 * (q.w * q.z + q.x * q.y);
    final double cosrCosp = 1 - 2 * (q.y * q.y + q.z * q.z);
    return atan2(sinrCosp, cosrCosp);
  }

  double get yaw {
    final vmath.Quaternion q = rotationQuaternion;
    final double sinyCosp = 2 * (q.w * q.y - q.z * q.x);
    final double cosyCosp = 1 - 2 * (q.x * q.x + q.y * q.y);
    return atan2(sinyCosp, cosyCosp);
  }

  bool get isSimulationMode => _isSimulationMode;
  // La configuración vive en el servicio, así que los cambios se aplican en tiempo real.
  bool get invertPitch => _service.invertPitch;
  bool get invertRoll => _service.invertRoll;
  bool get invertYaw => _service.invertYaw;
  bool get enableCompass => _service.enableCompass;
  bool get useGyroscope => _service.useGyroscope;

  /// Lecturas crudas de los sensores (para la detección de gestos).
  Stream<SensorSample> get accelerometerSamples => _service.accelerometerSamples;
  Stream<SensorSample> get gyroscopeSamples => _service.gyroscopeSamples;
  bool get hasMagnetometer => _service.hasMagnetometer;
  bool get hasGyroscope => _service.hasGyroscope;
  String get statusText => _statusText;
  Orientation get currentOrientation => _service.orientation;

  void updateOrientation(Orientation orientation) {
    if (_service.orientation != orientation) {
      _service.orientation = orientation;
      calibrateCurrentPosition();
    }
  }

  void calibrateCurrentPosition() {
    // Sin brújula, el yaw se re-centra solo hacia 0: se pone a 0 también aquí para
    // que la referencia de calibración y el re-centrado coincidan.
    if (!_service.enableCompass) {
      _service.resetYaw();
      _currentQuaternion = _service.currentQuaternion;
    }
    _calibrationOffset = vmath.Quaternion(
      -_currentQuaternion.x,
      -_currentQuaternion.y,
      -_currentQuaternion.z,
      _currentQuaternion.w,
    );
    notifyListeners();
  }

  void resetCalibration() {
    _calibrationOffset = vmath.Quaternion.identity();
    notifyListeners();
  }

  void toggleInvertPitch() {
    _service.invertPitch = !_service.invertPitch;
    notifyListeners();
  }

  void toggleInvertRoll() {
    _service.invertRoll = !_service.invertRoll;
    notifyListeners();
  }

  void toggleInvertYaw() {
    _service.invertYaw = !_service.invertYaw;
    notifyListeners();
  }

  /// Activa o desactiva el giroscopio en la fusión de sensores.
  void toggleGyroscope() {
    _service.useGyroscope = !_service.useGyroscope;
    notifyListeners();
  }

  /// Activa o desactiva la corrección del yaw con la brújula (magnetómetro).
  void toggleCompass() {
    _service.enableCompass = !_service.enableCompass;
    notifyListeners();
  }

  void setSimulationMode(bool enabled) {
    _isSimulationMode = enabled;
    notifyListeners();
  }

  void updateSimulationAngles(double pitchDeg, double rollDeg, [double yawDeg = 0.0]) {
    if (!_isSimulationMode) _isSimulationMode = true;
    _simulatedPitch = pitchDeg * pi / 180;
    _simulatedRoll = rollDeg * pi / 180;
    _simulatedYaw = yawDeg * pi / 180;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
