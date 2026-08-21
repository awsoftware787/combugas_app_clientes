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
    final screenSize = tester.getSize(find.byType(Scaffold));
    final dialogSize = tester.getSize(
      find.byKey(const ValueKey('searchable-selector-dialog')),
    );

    expect(dialogSize.width, closeTo(screenSize.width * 0.88, 1));
    expect(dialogSize.height, closeTo(screenSize.height * 0.52, 1));
    expect(find.text('Seleccionar colonia'), findsOneWidget);
    expect(find.text('Buscar colonia...'), findsOneWidget);
    expect(find.byTooltip('Cerrar'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('searchable-selector-option-0')))
          .height,
      50,
    );

    await tester.enterText(
      find.byKey(const ValueKey('searchable-selector-search')),
      'CeNt',
    );
    await tester.pump();

    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Centro Histórico'), findsOneWidget);
    expect(find.text('Las Fuentes'), findsNothing);
    expect(find.text('Nueva California'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('searchable-selector-search')),
      'sin coincidencias',
    );
    await tester.pump();
    expect(find.text('No se encontraron resultados'), findsOneWidget);
  });
}
