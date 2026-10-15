import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

class Sensor3DController extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<MagnetometerEvent>? _magSubscription;

  Orientation _currentOrientation = Orientation.portrait;

  vmath.Vector3 _latestAcc = vmath.Vector3(0, 0.98, 0);
  vmath.Vector3 _latestMag = vmath.Vector3(0, 1, 0);

  vmath.Quaternion _currentQuaternion = vmath.Quaternion.identity();
  vmath.Quaternion _calibrationOffset = vmath.Quaternion.identity();

  bool _invertPitch = true;
  bool _invertRoll = false;
  bool _invertYaw = false;

  bool _enableCompass = true;
  bool _hasMagnetometer = false;
  String _sensorStatusText = 'Iniciando sensores...';

  double _smoothingFactor = 0.15;

  bool _isSimulationMode = false;
  double _simulatedPitch = 0.0;
  double _simulatedRoll = 0.0;
  double _simulatedYaw = 0.0;

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
  bool get enableCompass => _enableCompass;
  bool get hasMagnetometer => _hasMagnetometer;
  String get sensorStatusText => _sensorStatusText;
  double get smoothingFactor => _smoothingFactor;
  Orientation get currentOrientation => _currentOrientation;

  Sensor3DController() {
    _initSensors();
  }

  void updateOrientation(Orientation newOrientation) {
    if (_currentOrientation != newOrientation) {
      _currentOrientation = newOrientation;
      calibrateCurrentPosition();
    }
  }

  void _initSensors() {
    _accSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_isSimulationMode) return;

      if (_currentOrientation == Orientation.portrait) {
        _latestAcc = vmath.Vector3(event.x, event.y, event.z);
      } else {
        _latestAcc = vmath.Vector3(-event.y, event.x, event.z);
      }

      _updateTiltCompensatedOrientation();
    }, onError: (dynamic error) {
      _sensorStatusText = 'Error en acelerómetro';
      _isSimulationMode = true;
      notifyListeners();
    });

    _magSubscription = magnetometerEventStream().listen((MagnetometerEvent event) {
      if (_isSimulationMode) return;
      _hasMagnetometer = true;

      if (_currentOrientation == Orientation.portrait) {
        _latestMag = vmath.Vector3(event.x, event.y, event.z);
      } else {
        _latestMag = vmath.Vector3(-event.y, event.x, event.z);
      }

      _sensorStatusText = 'Brújula Compensada (OK)';
      _updateTiltCompensatedOrientation();
    }, onError: (dynamic error) {
      _hasMagnetometer = false;
      _sensorStatusText = 'Sin Magnetómetro (Solo Acelerómetro)';
      notifyListeners();
    });

    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (_isSimulationMode) return;

      const double dt = 0.016;
      final vmath.Vector3 gyroVec = vmath.Vector3(event.x, event.y, event.z);
      final double speed = gyroVec.length;
      if (speed > 0.01) {
        final vmath.Quaternion gyroDelta = vmath.Quaternion.axisAngle(gyroVec.normalized(), speed * dt);
        _currentQuaternion = _currentQuaternion * gyroDelta;
        _currentQuaternion.normalize();
        notifyListeners();
      }
    }, onError: (_) {});
  }

  void _updateTiltCompensatedOrientation() {
    final double ax = _latestAcc.x;
    final double ay = _latestAcc.y;
    final double az = _latestAcc.z;

    final double normAcc = sqrt(ax * ax + ay * ay + az * az);
    if (normAcc == 0) return;

    final double pitchRad = atan2(ay, sqrt(ax * ax + az * az));
    final double rollRad = atan2(-ax, max(az, 0.05));

    double yawRad = 0.0;
    if (_enableCompass && _hasMagnetometer && _latestMag.length2 > 0) {
      final double mx = _latestMag.x;
      final double my = _latestMag.y;
      final double mz = _latestMag.z;

      final double sinP = sin(pitchRad);
      final double cosP = cos(pitchRad);
      final double sinR = sin(rollRad);
      final double cosR = cos(rollRad);

      final double bx = mx * cosR + mz * sinR;
      final double by = mx * sinP * sinR + my * cosP - mz * sinP * cosR;

      if (cosP.abs() > 0.1) {
        yawRad = atan2(-bx, by);
      }
    }

    final double p = _invertPitch ? -pitchRad : pitchRad;
    final double r = _invertRoll ? -rollRad : rollRad;
    final double y = _invertYaw ? -yawRad : yawRad;

    final vmath.Quaternion qPitch = vmath.Quaternion.axisAngle(vmath.Vector3(1, 0, 0), p);
    final vmath.Quaternion qRoll = vmath.Quaternion.axisAngle(vmath.Vector3(0, 1, 0), r);
    final vmath.Quaternion qYaw = vmath.Quaternion.axisAngle(vmath.Vector3(0, 0, 1), y);

    final vmath.Quaternion targetQ = qYaw * qPitch * qRoll;

    _currentQuaternion = _slerpQuaternions(_currentQuaternion, targetQ, _smoothingFactor);
    notifyListeners();
  }

  vmath.Quaternion _slerpQuaternions(vmath.Quaternion q1, vmath.Quaternion q2, double t) {
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

    return vmath.Quaternion(
      (s0 * q1.x) + (s1 * targetQ2.x),
      (s0 * q1.y) + (s1 * targetQ2.y),
      (s0 * q1.z) + (s1 * targetQ2.z),
      (s0 * q1.w) + (s1 * targetQ2.w),
    );
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

  void toggleCompass(bool enable) {
    _enableCompass = enable;
    notifyListeners();
  }

  void setSmoothingFactor(double factor) {
    _smoothingFactor = factor.clamp(0.01, 1.0);
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
    _accSubscription?.cancel();
    _gyroSubscription?.cancel();
    _magSubscription?.cancel();
    super.dispose();
  }
}
