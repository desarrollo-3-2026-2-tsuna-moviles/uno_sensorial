import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/physics_body_model.dart';
import 'physics_engine_interface.dart';

// Tipos C de FFI preparados para enlazar la librería compilada C++20
typedef NativeStepFunc = Void Function(Float deltaTime);
typedef DartStepFunc = void Function(double deltaTime);

/// Conector `dart:ffi` para cargar y ejecutar el motor de físicas agnóstico N-D compilado en C++20.
class CppPhysicsBridge implements PhysicsEngineInterface {
  DynamicLibrary? _nativeLib;
  bool _isNativeAvailable = false;

  final Map<String, PhysicsBodyModel> _fallbackBodies = <String, PhysicsBodyModel>{};

  bool get isNativeAvailable => _isNativeAvailable;

  CppPhysicsBridge() {
    _initNativeLibrary();
  }

  void _initNativeLibrary() {
    try {
      // Intentar cargar la librería dinámica C++20 según la plataforma
      // en Android: libuno_physics.so, en iOS/macOS: Framework/dylib
      _nativeLib = DynamicLibrary.open('libuno_physics.so');
      _isNativeAvailable = true;
      debugPrint('Motor de Físicas C++20 cargado exitosamente mediante FFI.');
    } catch (e) {
      _isNativeAvailable = false;
      debugPrint('Librería C++20 no disponible aún. Utilizando modo fallback: $e');
    }
  }

  @override
  void stepSimulation(double deltaTime) {
    if (_isNativeAvailable && _nativeLib != null) {
      // Llamar función exportada en C++20
      // final DartStepFunc nativeStep = _nativeLib!.lookupFunction<NativeStepFunc, DartStepFunc>('physics_step');
      // nativeStep(deltaTime);
    } else {
      // Simulación de respaldo
      for (final PhysicsBodyModel body in _fallbackBodies.values) {
        body.position.add(body.velocity * deltaTime);
        body.velocity.scale(0.92);
      }
    }
  }

  @override
  void addBody(PhysicsBodyModel body) {
    _fallbackBodies[body.id] = body;
  }

  @override
  void removeBody(String bodyId) {
    _fallbackBodies.remove(bodyId);
  }

  @override
  vmath.Vector3 getBodyPosition(String bodyId) {
    return _fallbackBodies[bodyId]?.position ?? vmath.Vector3.zero();
  }

  @override
  vmath.Quaternion getBodyRotation(String bodyId) {
    return _fallbackBodies[bodyId]?.rotation ?? vmath.Quaternion.identity();
  }

  @override
  void applyImpulse(String bodyId, vmath.Vector3 impulse) {
    _fallbackBodies[bodyId]?.velocity.add(impulse);
  }

  @override
  void dispose() {
    _fallbackBodies.clear();
  }
}
