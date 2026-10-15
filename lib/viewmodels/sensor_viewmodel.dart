import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../services/sensor_service.dart';

/// ViewModel que expone el estado de los sensores 3D a las vistas (Views)
class SensorViewModel extends ChangeNotifier {
  final SensorService _service = SensorService();

  vmath.Quaternion _currentQuaternion = vmath.Quaternion.identity();
  vmath.Quaternion _calibrationOffset = vmath.Quaternion.identity();

  bool _invertPitch = true;
  bool _invertRoll = false;
  bool _invertYaw = false;
  final bool _enableCompass = true;

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
      invertPitch: _invertPitch,
      invertRoll: _invertRoll,
      invertYaw: _invertYaw,
      enableCompass: _enableCompass,
    );
  }

  vmath.Quaternion get rotationQuaternion {
    if (_isSimulationMode) {
      final double px = _invertPitch ? -_simulatedPitch : _simulatedPitch;
      final double ry = _invertRoll ? -_simulatedRoll : _simulatedRoll;
      final double yz = _invertYaw ? -_simulatedYaw : _simulatedYaw;

      final vmath.Quaternion qX = vmath.Quaternion.axisAngle(vmath.Vector3(1, 0, 0), px);
      final vmath.Quaternion qY = vmath.Quaternion.axisAngle(vmath.Vector3(0, 1, 0), yz);
      final vmath.Quaternion qZ = vmath.Quaternion.axisAngle(vmath.Vector3(0, 0, 1), ry);
      return qY * qX * qZ;
    }

    final vmath.Quaternion result = _calibrationOffset * _currentQuaternion;
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
  bool get invertPitch => _invertPitch;
  bool get invertRoll => _invertRoll;
  bool get invertYaw => _invertYaw;
  bool get hasMagnetometer => _service.hasMagnetometer;
  String get statusText => _statusText;

  void updateOrientation(Orientation orientation) {
    if (_service.orientation != orientation) {
      _service.orientation = orientation;
      calibrateCurrentPosition();
    }
  }

  void calibrateCurrentPosition() {
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
    _invertPitch = !_invertPitch;
    notifyListeners();
  }

  void toggleInvertRoll() {
    _invertRoll = !_invertRoll;
    notifyListeners();
  }

  void toggleInvertYaw() {
    _invertYaw = !_invertYaw;
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
