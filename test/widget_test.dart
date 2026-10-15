import 'package:flutter_test/flutter_test.dart';
import 'package:uno_game/main.dart';

void main() {
  testWidgets('Carga inicial de la app UnoGameApp', (WidgetTester tester) async {
    await tester.pumpWidget(const UnoGameApp());
    expect(find.byType(UnoGameApp), findsOneWidget);
  });
}
