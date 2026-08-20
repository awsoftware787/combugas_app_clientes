import 'package:combugas_clientes/shared/widgets/searchable_dropdown_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filtra por coincidencia parcial sin distinguir mayúsculas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchableDropdownFormField<String>(
            key: const ValueKey('colonia-selector'),
            value: null,
            items: const [
              'Centro',
              'Centro Histórico',
              'Las Fuentes',
              'Nueva California',
            ],
            itemLabel: (value) => value,
            labelText: 'Colonia',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('colonia-selector')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('searchable-selector-search')),
      'CeNt',
    );
    await tester.pump();

    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Centro Histórico'), findsOneWidget);
    expect(find.text('Las Fuentes'), findsNothing);
    expect(find.text('Nueva California'), findsNothing);
  });
}
