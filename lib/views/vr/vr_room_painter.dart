import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../widgets/table_geometry.dart';
import 'pseudo_view.dart';

/// Sala + mesa vistas desde el asiento local. El fondo se desplaza con el giro de la
/// cabeza (panorama) y la mesa se proyecta sobre el plano con `PseudoView`.
class VrRoomPainter extends CustomPainter {
  VrRoomPainter({required this.view, required this.seatCount, required this.turnSeat});

  final PseudoView view;
  final int seatCount;

  /// Posición en la lista del jugador con el turno (-1 si ninguno).
  final int turnSeat;

  static const double _thickness = 26.0;
  static const int _segments = 64;

  @override
  void paint(Canvas canvas, Size size) {
    _paintRoom(canvas, size);
    _paintTable(canvas, size);
  }

  // ---------------------------------------------------------------- sala

  void _paintRoom(Canvas canvas, Size size) {
    final double h = view.horizon.clamp(0.0, size.height);

    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, max(h, 1)),
          const <Color>[Color(0xFF070B14), Color(0xFF2B3047)],
        ),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, h, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h),
          Offset(0, size.height),
          const <Color>[Color(0xFF241810), Color(0xFF060403)],
        ),
    );

    // Decoración mural: cada 30° hay un cuadro o una lámpara. Al girar la cabeza se desplazan.
    final double u = view.ui;
    for (int i = -6; i < 6; i++) {
      final double azimuth = (i * 30 + 15) * pi / 180;
      final double theta = azimuth - view.yaw;
      if (theta.abs() > 80 * pi / 180) continue;

      final double x = size.width / 2 + view.focal * tan(theta);
      final double squash = cos(theta);

      if (i.isEven) {
        final Rect frame = Rect.fromCenter(
          center: Offset(x, view.horizon - 120 * u),
          width: 90 * u * squash,
          height: 58 * u,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(frame.inflate(4 * u), const Radius.circular(3)),
          Paint()..color = const Color(0xFF5A3A1A),
        );
        canvas.drawRect(
          frame,
          Paint()
            ..shader = ui.Gradient.linear(
              frame.topLeft,
              frame.bottomRight,
              <Color>[
                Colors.indigo.shade900,
                Colors.teal.shade700,
              ],
            ),
        );
      } else {
        final Offset lamp = Offset(x, view.horizon - 150 * u);
        canvas.drawCircle(
          lamp,
          80 * u,
          Paint()
            ..shader = ui.Gradient.radial(
              lamp,
              80 * u,
              <Color>[Colors.amber.withValues(alpha: 0.55), Colors.transparent],
            ),
        );
        canvas.drawCircle(lamp, 6 * u, Paint()..color = const Color(0xFFFFE9A8));
      }
    }

    // Línea de zócalo en el horizonte
    canvas.drawLine(
      Offset(0, h),
      Offset(size.width, h),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..strokeWidth = 3 * u,
    );
  }

  // --------------------------------------------------------------- mesa

  /// Anillo del plano de la mesa -> polígono en pantalla, recortado contra `near`.
  Path? _polygon(double radius, double height, {double cx = 0, double cz = 0, int segments = _segments}) {
    final List<({double lateral, double forward})> pts = <({double lateral, double forward})>[
      for (int i = 0; i < segments; i++)
        view.toLocal(
          cx + radius * cos(2 * pi * i / segments),
          cz + radius * sin(2 * pi * i / segments),
        ),
    ];

    final List<({double lateral, double forward})> clipped = <({double lateral, double forward})>[];
    for (int i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      final bool aIn = a.forward >= view.near;
      final bool bIn = b.forward >= view.near;
      if (aIn) clipped.add(a);
      if (aIn != bIn) {
        final double t = (view.near - a.forward) / (b.forward - a.forward);
        clipped.add((
          lateral: a.lateral + (b.lateral - a.lateral) * t,
          forward: view.near,
        ));
      }
    }
    if (clipped.length < 3) return null;

    final Path path = Path();
    for (int i = 0; i < clipped.length; i++) {
      final Offset p = view.projectLocal(clipped[i].lateral, clipped[i].forward, height);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  void _paintTable(Canvas canvas, Size size) {
    final double r = view.tableRadius;

    // Sombra en el suelo y grosor de la mesa (anillo inferior desplazado)
    final Path? shadow = _polygon(r * 1.12, -view.eyeHeight * 1.6);
    if (shadow != null) {
      canvas.drawPath(shadow, Paint()..color = Colors.black.withValues(alpha: 0.45));
    }
    final Path? pedestal = _polygon(r * 0.16, -_thickness * 4);
    if (pedestal != null) canvas.drawPath(pedestal, Paint()..color = const Color(0xFF2A1A0C));

    final Path? underside = _polygon(r, -_thickness);
    if (underside != null) canvas.drawPath(underside, Paint()..color = const Color(0xFF3A210D));

    final Path? rim = _polygon(r, 0);
    if (rim == null) return;
    canvas.drawPath(rim, Paint()..color = const Color(0xFF8B5A2B));

    final Path? felt = _polygon(r * 0.95, 0);
    if (felt != null) {
      final ScenePoint c = view.project(0, 0);
      final Paint paint = Paint();
      if (c.visible) {
        paint.shader = ui.Gradient.radial(
          Offset(c.x, c.y),
          max(size.width, size.height) * 0.55,
          const <Color>[Color(0xFF2E8B3A), Color(0xFF1B5E20), Color(0xFF0B300E)],
          const <double>[0.0, 0.6, 1.0],
        );
      } else {
        paint.color = const Color(0xFF1B5E20);
      }
      canvas.drawPath(felt, paint);
    }

    canvas.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * view.ui
        ..color = const Color(0xFFFFD700),
    );

    final Path? inner = _polygon(r * 0.62, 0);
    if (inner != null) {
      canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.10),
      );
    }

    // Sitios de cada jugador; el del turno se ilumina
    for (int k = 0; k < seatCount; k++) {
      final Offset pos = TableGeometry.seatPosition(k, seatCount, r * 0.84);
      final Path? mat = _polygon(38, 0, cx: pos.dx, cz: pos.dy, segments: 20);
      if (mat == null) continue;
      final bool isTurn = k == turnSeat;
      final Color base = isTurn ? Colors.amberAccent : Colors.white;
      canvas.drawPath(mat, Paint()..color = base.withValues(alpha: isTurn ? 0.30 : 0.06));
      canvas.drawPath(
        mat,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isTurn ? 2.5 : 1
          ..color = base.withValues(alpha: isTurn ? 0.9 : 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant VrRoomPainter old) => true;
}
