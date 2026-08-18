import 'package:combugas_clientes/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla temporal', (WidgetTester tester) async {
    await tester.pumpWidget(const CombugasApp());

    expect(find.text('Combugas Clientes'), findsOneWidget);
  });
}
