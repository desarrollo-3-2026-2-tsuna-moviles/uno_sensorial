import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_game/views/widgets/table_geometry.dart';

void main() {
  group('TableGeometry', () {
    for (int n = 2; n <= 10; n++) {
      test('$n asientos: espaciado igual, simetría y local abajo', () {
        final double r = TableGeometry.tableRadius(n);
        final seats = [for (int k = 0; k < n; k++) TableGeometry.seatPosition(k, n, r)];

        // Asiento local en el borde cercano (abajo, centrado)
        expect(seats[0].dx, closeTo(0, 1e-9));
        expect(seats[0].dy, closeTo(r, 1e-9));

        // Todos a la misma distancia del centro y con la misma separación entre vecinos
        final double chord = (seats[1] - seats[0]).distance;
        for (int k = 0; k < n; k++) {
          expect(seats[k].distance, closeTo(r, 1e-9));
          expect((seats[(k + 1) % n] - seats[k]).distance, closeTo(chord, 1e-9));
        }

        // Simetría respecto al eje vertical: cada asiento k tiene su espejo n-k
        for (int k = 1; k < n; k++) {
          expect(seats[k].dx, closeTo(-seats[n - k].dx, 1e-9));
          expect(seats[k].dy, closeTo(seats[n - k].dy, 1e-9));
        }

        // Los vecinos nunca se solapan
        if (n > 2) expect(chord, greaterThanOrEqualTo(TableGeometry.seatWidth));
      });
    }

    test('el radio crece de forma monótona con los jugadores', () {
      double prev = 0;
      for (int n = 2; n <= 30; n++) {
        final double r = TableGeometry.tableRadius(n);
        expect(r, greaterThanOrEqualTo(prev));
        prev = r;
      }
      expect(TableGeometry.tableRadius(30), greaterThan(TableGeometry.minRadius));
      expect(TableGeometry.seatAngle(1, 4), closeTo(pi / 2, 1e-9));
    });
  });
}
