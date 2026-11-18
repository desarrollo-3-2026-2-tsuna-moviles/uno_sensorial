import 'package:vector_math/vector_math_64.dart' as vmath;

/// Modelo de cuerpo rígido 3D en la mesa de juego (Mazo, Cartas, Fichas)
class PhysicsBodyModel {
  final String id;
  vmath.Vector3 position;
  vmath.Quaternion rotation;
  vmath.Vector3 velocity;
  vmath.Vector3 angularVelocity;

  PhysicsBodyModel({
    required this.id,
    vmath.Vector3? position,
    vmath.Quaternion? rotation,
    vmath.Vector3? velocity,
    vmath.Vector3? angularVelocity,
  })  : position = position ?? vmath.Vector3.zero(),
        rotation = rotation ?? vmath.Quaternion.identity(),
        velocity = velocity ?? vmath.Vector3.zero(),
        angularVelocity = angularVelocity ?? vmath.Vector3.zero();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'px': position.x,
        'py': position.y,
        'pz': position.z,
        'qx': rotation.x,
        'qy': rotation.y,
        'qz': rotation.z,
        'qw': rotation.w,
      };

  factory PhysicsBodyModel.fromJson(Map<String, dynamic> json) {
    return PhysicsBodyModel(
      id: json['id'] as String,
      position: vmath.Vector3(
        (json['px'] as num).toDouble(),
        (json['py'] as num).toDouble(),
        (json['pz'] as num).toDouble(),
      ),
      rotation: vmath.Quaternion(
        (json['qx'] as num).toDouble(),
        (json['qy'] as num).toDouble(),
        (json['qz'] as num).toDouble(),
        (json['qw'] as num).toDouble(),
      ),
    );
  }
}
