import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/physics_body_model.dart';
import 'physics_engine_interface.dart';

/// Implementación en Dart puro de PhysicsEngineInterface para desarrollo en paralelo
/// mientras se construye el motor de físicas en C++20.
class MockPhysicsService implements PhysicsEngineInterface {
  final Map<String, PhysicsBodyModel> _bodies = <String, PhysicsBodyModel>{};

  @override
  void addBody(PhysicsBodyModel body) {
    _bodies[body.id] = body;
  }

  @override
  void removeBody(String bodyId) {
    _bodies.remove(bodyId);
  }

  @override
  vmath.Vector3 getBodyPosition(String bodyId) {
    return _bodies[bodyId]?.position ?? vmath.Vector3.zero();
  }

  @override
  vmath.Quaternion getBodyRotation(String bodyId) {
    return _bodies[bodyId]?.rotation ?? vmath.Quaternion.identity();
  }

  @override
  void applyImpulse(String bodyId, vmath.Vector3 impulse) {
    final PhysicsBodyModel? body = _bodies[bodyId];
    if (body != null) {
      body.velocity.add(impulse);
    }
  }

  @override
  void stepSimulation(double deltaTime) {
    for (final PhysicsBodyModel body in _bodies.values) {
      // Integración cinemática simple P = P + V * dt
      body.position.add(body.velocity * deltaTime);
      // Fricción/Resistencia del aire
      body.velocity.scale(0.92);
    }
  }

  @override
  void dispose() {
    _bodies.clear();
  }
}
