import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/core/theme/app_theme.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/pedidos/widgets/producto_icono.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el skeleton tiene espacio y contraste con el tema de la app', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 200,
            child: ProductoIcono.producto(
              producto: _producto(null),
              showLoadingSkeleton: true,
            ),
          ),
        ),
      ),
    );

    final skeleton = find.bySemanticsLabel('Cargando imagen del producto');
    expect(skeleton, findsOneWidget);
    final box = find.descendant(
      of: skeleton,
      matching: find.byType(DecoratedBox),
    );
    expect(tester.getSize(box), const Size(192, 170));
    final decoration =
        tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFE0E0E0));
    expect(decoration.color, isNot(AppTheme.lightTheme.colorScheme.surface));
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final url in const <String?>[null, '', '   ', 'imagen-invalida']) {
    testWidgets('usa default.png cuando la URL es ${url ?? 'null'}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ProductoIcono.producto(producto: _producto(url))),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName, AppAssets.productFallback);
    });
  }

  testWidgets('mantiene una URL remota válida', (tester) async {
    const url = 'https://dominio.example/productos/icono.webp';

    await tester.pumpWidget(
      MaterialApp(home: ProductoIcono.producto(producto: _producto(url))),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect((image.image as NetworkImage).url, url);
    expect(image.errorBuilder, isNotNull);
  });
}

Producto _producto(String? urlIcono) => Producto(
  id: ProductoIds.cilindro30,
  descripcion: 'CILINDRO 30 KG',
  presentacion: '30 KG',
  servicioId: ServicioIds.gas,
  precioCentavos: 60000,
  urlIcono: urlIcono,
);
