import 'dart:math';
import 'dart:ui';

/// Geometría pura de la mesa redonda. El asiento 0 es el jugador local, en el
/// borde cercano a la cámara; el resto avanza en sentido horario visto desde arriba.
/// Las posiciones están en el plano de la mesa: dx a la derecha, dy hacia la cámara.
class TableGeometry {
  TableGeometry._();

  /// Ancho reservado por asiento: deja sitio para que cada jugador sostenga su mano
  /// frente a sí (a futuro, ocultándola como en la vida real).
  static const double seatWidth = 120.0;
  static const double seatHeight = 76.0;
  static const double seatGap = 36.0;
  static const double minRadius = 260.0;

  static double seatAngle(int seat, int totalSeats) => 2 * pi * seat / totalSeats;

  /// Radio que mantiene constante la separación entre asientos al crecer N.
  static double tableRadius(int totalSeats) =>
      max(minRadius, totalSeats * (seatWidth + seatGap) / (2 * pi));

  static Offset seatPosition(int seat, int totalSeats, double radius) {
    final double a = seatAngle(seat, totalSeats);
    return Offset(-radius * sin(a), radius * cos(a));
  }
}
