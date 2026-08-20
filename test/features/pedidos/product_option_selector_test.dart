import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/pedidos/widgets/product_option_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra cilindros circulares y cambia la selección', (
    tester,
  ) async {
    var selected = 0;
    const products = [
      Producto(
        id: ProductoIds.cilindro30,
        descripcion: 'CILINDRO 30 KG',
        presentacion: '30 KG',
        servicioId: ServicioIds.gas,
        precioCentavos: 60000,
      ),
      Producto(
        id: ProductoIds.cilindro45,
        descripcion: 'CILINDRO 45 KG',
        presentacion: '45 KG',
        servicioId: ServicioIds.gas,
        precioCentavos: 90000,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder:
              (context, setState) => Scaffold(
                body: ProductOptionSelector(
                  products: products,
                  selectedIndex: selected,
                  onSelected: (value) => setState(() => selected = value),
                ),
              ),
        ),
      ),
    );

    expect(find.text('30kg'), findsOneWidget);
    expect(find.text('45kg'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('product-option-2'))),
      const Size.square(58),
    );
    expect(_color(tester, ProductoIds.cilindro30), AppColors.accent);
    expect(_color(tester, ProductoIds.cilindro45), AppColors.secondary);

    await tester.tap(find.byKey(const ValueKey('product-option-3')));
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(_color(tester, ProductoIds.cilindro30), AppColors.secondary);
    expect(_color(tester, ProductoIds.cilindro45), AppColors.accent);
  });

  testWidgets('usa el nombre de presentación para croquetas', (tester) async {
    const product = Producto(
      id: 20,
      descripcion: 'BULTO DE ADULTO 20 KG',
      presentacion: '20 KG',
      servicioId: ServicioIds.croquetas,
      precioCentavos: 40000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductOptionSelector(
            products: [product],
            selectedIndex: 0,
            onSelected: _ignore,
          ),
        ),
      ),
    );

    expect(find.text('ADULTO 20 KG'), findsOneWidget);
    expect(_color(tester, product.id), AppColors.accent);
  });
}

Color? _color(WidgetTester tester, int productId) {
  final container = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('product-option-$productId')),
  );
  return (container.decoration as BoxDecoration).color;
}

void _ignore(int _) {}
