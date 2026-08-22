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

  testWidgets('modo tarjetas soporta más de dos variantes', (tester) async {
    var selected = 0;
    const products = [
      Producto(
        id: 20,
        descripcion: 'BULTO DE ADULTO 20 KG',
        presentacion: '20 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 40000,
      ),
      Producto(
        id: 21,
        descripcion: 'BULTO DE CACHORRO 20 KG',
        presentacion: '20 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 42000,
      ),
      Producto(
        id: 22,
        descripcion: 'BULTO RAZA PEQUEÑA 10 KG',
        presentacion: '10 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 38000,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: StatefulBuilder(
                builder:
                    (context, setState) => ProductOptionSelector(
                      products: products,
                      selectedIndex: selected,
                      layout: ProductOptionSelectorLayout.cards,
                      onSelected: (value) => setState(() => selected = value),
                    ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('product-option-20'))),
      const Size(136, 58),
    );
    expect(_borderColor(tester, 20), AppColors.accent);
    expect(_borderColor(tester, 21), AppColors.secondary);

    await tester.tap(find.byKey(const ValueKey('product-option-21')));
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(_borderColor(tester, 20), AppColors.secondary);
    expect(_borderColor(tester, 21), AppColors.accent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modo segmentos muestra tres opciones completas', (tester) async {
    var selected = 0;
    const products = [
      Producto(
        id: 20,
        descripcion: 'BULTO DE ADULTO 20 KG',
        presentacion: '20 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 40000,
      ),
      Producto(
        id: 21,
        descripcion: 'BULTO DE CACHORRO 20 KG',
        presentacion: '20 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 42000,
      ),
      Producto(
        id: 22,
        descripcion: 'BULTO RAZA PEQUEÑA 10 KG',
        presentacion: '10 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 38000,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: StatefulBuilder(
                builder:
                    (context, setState) => ProductOptionSelector(
                      products: products,
                      selectedIndex: selected,
                      layout: ProductOptionSelectorLayout.segments,
                      onSelected: (value) => setState(() => selected = value),
                    ),
              ),
            ),
          ),
        ),
      ),
    );

    final firstSize = tester.getSize(
      find.byKey(const ValueKey('product-option-20')),
    );
    final thirdRect = tester.getRect(
      find.byKey(const ValueKey('product-option-22')),
    );
    final selectorRect = tester.getRect(find.byType(ProductOptionSelector));

    expect(firstSize.width, closeTo((280 - 12) / 3, 0.1));
    expect(firstSize.height, 48);
    expect(thirdRect.right, lessThanOrEqualTo(selectorRect.right));
    expect(
      find.byKey(const ValueKey('product-options-previous')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('product-options-next')), findsNothing);
    expect(_color(tester, 20), AppColors.accent);
    expect(_color(tester, 21), AppColors.white);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('product-option-21')));
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(_color(tester, 20), AppColors.white);
    expect(_color(tester, 21), AppColors.accent);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'modo segmentos centra una opción con el mismo ancho del caso de dos',
    (tester) async {
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
            body: Center(
              child: SizedBox(
                width: 280,
                child: ProductOptionSelector(
                  products: [product],
                  selectedIndex: 0,
                  layout: ProductOptionSelectorLayout.segments,
                  onSelected: _ignore,
                ),
              ),
            ),
          ),
        ),
      );

      final optionRect = tester.getRect(
        find.byKey(const ValueKey('product-option-20')),
      );
      final selectorRect = tester.getRect(find.byType(ProductOptionSelector));

      expect(optionRect.width, closeTo((280 - 6) / 2, 0.1));
      expect(optionRect.height, 48);
      expect(optionRect.center.dx, closeTo(selectorRect.center.dx, 0.1));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    },
  );

  testWidgets('modo segmentos muestra flechas y desplaza con cuatro opciones', (
    tester,
  ) async {
    const products = [
      Producto(
        id: 20,
        descripcion: 'BULTO DE ADULTO 20 KG',
        presentacion: '20 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 40000,
      ),
      Producto(
        id: 21,
        descripcion: 'BULTO DE CACHORRO 20 KG',
        presentacion: '20 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 42000,
      ),
      Producto(
        id: 22,
        descripcion: 'BULTO RAZA PEQUEÑA 10 KG',
        presentacion: '10 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 38000,
      ),
      Producto(
        id: 23,
        descripcion: 'BULTO PREMIUM 15 KG',
        presentacion: '15 KG',
        servicioId: ServicioIds.croquetas,
        precioCentavos: 45000,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: ProductOptionSelector(
                products: products,
                selectedIndex: 0,
                layout: ProductOptionSelectorLayout.segments,
                onSelected: _ignore,
              ),
            ),
          ),
        ),
      ),
    );

    final firstFinder = find.byKey(const ValueKey('product-option-20'));
    final thirdRect = tester.getRect(
      find.byKey(const ValueKey('product-option-22')),
    );
    final rightArrowRect = tester.getRect(
      find.byKey(const ValueKey('product-options-next')),
    );
    final initialFirstX = tester.getTopLeft(firstFinder).dx;

    expect(
      find.byKey(const ValueKey('product-options-previous')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('product-options-next')), findsOneWidget);
    expect(thirdRect.right, lessThanOrEqualTo(rightArrowRect.left));

    await tester.tap(find.byKey(const ValueKey('product-options-next')));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(firstFinder).dx, lessThan(initialFirstX));
    expect(tester.takeException(), isNull);
  });
}

Color? _color(WidgetTester tester, int productId) {
  final container = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('product-option-$productId')),
  );
  return (container.decoration as BoxDecoration).color;
}

Color _borderColor(WidgetTester tester, int productId) {
  final container = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('product-option-$productId')),
  );
  final border = (container.decoration as BoxDecoration).border! as Border;
  return border.top.color;
}

void _ignore(int _) {}
