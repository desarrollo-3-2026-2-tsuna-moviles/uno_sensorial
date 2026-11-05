import 'package:vector_math/vector_math_64.dart' as vmath;
import '../models/physics_body_model.dart';

/// Contrato/Interfaz abstracta para el motor de físicas.
/// Permite intercambiar entre la simulación simulada en Dart y la implementación nativa FFI C++20 sin modificar la UI.
abstract class PhysicsEngineInterface {
  /// Avanza la simulación física el intervalo de tiempo dado
  void stepSimulation(double deltaTime);

  /// Registra un nuevo cuerpo rígido en la simulación 3D
  void addBody(PhysicsBodyModel body);

  /// Elimina un cuerpo rígido de la simulación
  void removeBody(String bodyId);

  /// Retorna la posición 3D actual de un cuerpo
  vmath.Vector3 getBodyPosition(String bodyId);

  /// Retorna la orientación en Cuaternión 3D de un cuerpo
  vmath.Quaternion getBodyRotation(String bodyId);

  /// Aplica un impulso de fuerza 3D a un cuerpo
  void applyImpulse(String bodyId, vmath.Vector3 impulse);

  /// Libera recursos del motor
  void dispose();
}
