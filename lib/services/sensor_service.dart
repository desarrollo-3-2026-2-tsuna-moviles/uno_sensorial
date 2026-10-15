import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

/// Servicio de capa Data/Service que gestiona el hardware de acelerómetro, magnetómetro y giroscopio.
class SensorService {
  StreamSubscription<AccelerometerEvent>? _accSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<MagnetometerEvent>? _magSubscription;

  Orientation orientation = Orientation.portrait;
  vmath.Vector3 latestAcc = vmath.Vector3(0, 0.98, 0);
  vmath.Vector3 latestMag = vmath.Vector3(0, 1, 0);
  vmath.Quaternion currentQuaternion = vmath.Quaternion.identity();

  bool hasMagnetometer = false;
  String statusText = 'Iniciando sensores...';

  void listen({
    required Function(vmath.Quaternion q) onSensorUpdate,
    required Function(String status) onStatusUpdate,
    bool invertPitch = true,
    bool invertRoll = false,
    bool invertYaw = false,
    bool enableCompass = true,
    double smoothingFactor = 0.15,
  }) {
    // Acelerómetro
    _accSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (orientation == Orientation.portrait) {
        latestAcc = vmath.Vector3(event.x, event.y, event.z);
      } else {
        latestAcc = vmath.Vector3(-event.y, event.x, event.z);
      }

      final vmath.Quaternion q = _computeQuaternion(
        invertPitch: invertPitch,
        invertRoll: invertRoll,
        invertYaw: invertYaw,
        enableCompass: enableCompass,
        smoothingFactor: smoothingFactor,
      );
      onSensorUpdate(q);
    }, onError: (dynamic error) {
      statusText = 'Error en acelerómetro';
      onStatusUpdate(statusText);
    });

    // Magnetómetro
    _magSubscription = magnetometerEventStream().listen((MagnetometerEvent event) {
      hasMagnetometer = true;
      statusText = 'Brújula Compensada (OK)';
      onStatusUpdate(statusText);

      if (orientation == Orientation.portrait) {
        latestMag = vmath.Vector3(event.x, event.y, event.z);
      } else {
        latestMag = vmath.Vector3(-event.y, event.x, event.z);
      }

      final vmath.Quaternion q = _computeQuaternion(
        invertPitch: invertPitch,
        invertRoll: invertRoll,
        invertYaw: invertYaw,
        enableCompass: enableCompass,
        smoothingFactor: smoothingFactor,
      );
      onSensorUpdate(q);
    }, onError: (_) {
      hasMagnetometer = false;
      statusText = 'Sin Magnetómetro (Solo Acelerómetro)';
      onStatusUpdate(statusText);
    });

    // Giroscopio
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      const double dt = 0.016;
      final vmath.Vector3 gyroVec = vmath.Vector3(event.x, event.y, event.z);
      final double speed = gyroVec.length;
      if (speed > 0.01) {
        final vmath.Quaternion gyroDelta = vmath.Quaternion.axisAngle(gyroVec.normalized(), speed * dt);
        currentQuaternion = currentQuaternion * gyroDelta;
        currentQuaternion.normalize();
        onSensorUpdate(currentQuaternion);
      }
    }, onError: (_) {});
  }

  vmath.Quaternion _computeQuaternion({
    required bool invertPitch,
    required bool invertRoll,
    required bool invertYaw,
    required bool enableCompass,
    required double smoothingFactor,
  }) {
    final double ax = latestAcc.x;
    final double ay = latestAcc.y;
    final double az = latestAcc.z;

    final double normAcc = sqrt(ax * ax + ay * ay + az * az);
    if (normAcc == 0) return currentQuaternion;

    final double nAx = ax / normAcc;
    final double nAy = ay / normAcc;
    final double nAz = az / normAcc;

    final double pitchRad = asin(nAy.clamp(-1.0, 1.0));
    final double rollRad = atan2(-nAx, max(nAz, 0.05));

    double yawRad = 0.0;
    if (enableCompass && hasMagnetometer && latestMag.length2 > 0) {
      final double mx = latestMag.x;
      final double my = latestMag.y;
      final double mz = latestMag.z;

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

    final double p = invertPitch ? -pitchRad : pitchRad;
    final double r = invertRoll ? -rollRad : rollRad;
    final double y = invertYaw ? -yawRad : yawRad;

    final vmath.Quaternion qPitch = vmath.Quaternion.axisAngle(vmath.Vector3(1, 0, 0), p);
    final vmath.Quaternion qRoll = vmath.Quaternion.axisAngle(vmath.Vector3(0, 1, 0), r);
    final vmath.Quaternion qYaw = vmath.Quaternion.axisAngle(vmath.Vector3(0, 0, 1), y);

    final vmath.Quaternion targetQ = qYaw * qPitch * qRoll;

    currentQuaternion = _slerp(currentQuaternion, targetQ, smoothingFactor);
    return currentQuaternion;
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

    return vmath.Quaternion(
      (s0 * q1.x) + (s1 * targetQ2.x),
      (s0 * q1.y) + (s1 * targetQ2.y),
      (s0 * q1.z) + (s1 * targetQ2.z),
      (s0 * q1.w) + (s1 * targetQ2.w),
    );
  }

  void dispose() {
    _accSubscription?.cancel();
    _gyroSubscription?.cancel();
    _magSubscription?.cancel();
  }
}
