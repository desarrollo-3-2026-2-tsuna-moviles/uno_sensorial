import 'package:flutter_test/flutter_test.dart';
import 'package:uno_game/services/gesture_service.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

void main() {
  late List<GestureType> detected;
  late GestureService service;
  final DateTime t0 = DateTime(2026, 1, 1);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

  // Teléfono boca arriba y quieto: el acelerómetro mide +g en Z.
  final vmath.Vector3 flat = vmath.Vector3(0, 0, 9.81);

  setUp(() {
    detected = <GestureType>[];
    service = GestureService(onGesture: detected.add);
    service.addAccelerometer(flat, at(0)); // Inicializa la gravedad.
  });

  group('RF-20 lanzar', () {
    test('un giro rápido hacia adelante lanza la carta', () {
      service.addGyroscope(vmath.Vector3(-5.0, 0, 0), at(20));
      expect(detected, <GestureType>[GestureType.throwCard]);
    });

    test('un giro lento o hacia atrás no lanza', () {
      service.addGyroscope(vmath.Vector3(-2.0, 0, 0), at(20));
      service.addGyroscope(vmath.Vector3(5.0, 0, 0), at(40));
      expect(detected, isEmpty);
    });

    test('respeta el umbral configurado y el tiempo de espera entre lanzamientos', () {
      service.throwThreshold = 6.0;
      service.addGyroscope(vmath.Vector3(-5.0, 0, 0), at(20));
      expect(detected, isEmpty);

      service.addGyroscope(vmath.Vector3(-7.0, 0, 0), at(40));
      service.addGyroscope(vmath.Vector3(-7.0, 0, 0), at(60)); // Dentro del cooldown.
      expect(detected, <GestureType>[GestureType.throwCard]);
    });
  });

  group('RF-21 giro de Reversa', () {
    void twist(double radPerSecond, {int fromMs = 20, int durationMs = 600}) {
      for (int ms = fromMs; ms <= fromMs + durationMs; ms += 20) {
        service.addGyroscope(vmath.Vector3(0, 0, radPerSecond), at(ms));
      }
    }

    test('no se detecta si el juego no lo espera', () {
      twist(4.0);
      expect(detected, isEmpty);
    });

    test('un giro de ~90° alrededor del eje vertical confirma la Reversa', () {
      service.reverseTwistEnabled = true;
      twist(4.0); // 4 rad/s * 0.6 s ≈ 137°
      expect(detected, <GestureType>[GestureType.reverseTwist]);
    });

    test('funciona en ambos sentidos de giro', () {
      service.reverseTwistEnabled = true;
      twist(-4.0);
      expect(detected, <GestureType>[GestureType.reverseTwist]);
    });

    test('un giro pequeño no basta', () {
      service.reverseTwistEnabled = true;
      twist(1.0, durationMs: 400); // ≈ 23°
      expect(detected, isEmpty);
    });
  });

  group('RF-22 sacudida para UNO', () {
    test('una sacudida corta hacia arriba canta UNO', () {
      service.addAccelerometer(vmath.Vector3(0, 0, 9.81 + 12), at(20));
      expect(detected, <GestureType>[GestureType.unoShake]);
    });

    test('una sacudida hacia abajo o de lado no canta UNO', () {
      service.addAccelerometer(vmath.Vector3(0, 0, 9.81 - 12), at(20));
      service.addAccelerometer(vmath.Vector3(12, 0, 9.81), at(40));
      expect(detected, isEmpty);
    });

    test('no se confunde con un lanzamiento (teléfono girando rápido)', () {
      service.throwThreshold = 100; // Desactiva el lanzamiento para aislar la prueba.
      service.addGyroscope(vmath.Vector3(-5.0, 0, 0), at(10));
      service.addAccelerometer(vmath.Vector3(0, 0, 9.81 + 12), at(20));
      expect(detected, isEmpty);
    });
  });
}
