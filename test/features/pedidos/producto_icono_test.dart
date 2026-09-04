import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/pedidos/widgets/producto_icono.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final url in const <String?>[null, '', '   ', 'imagen-invalida']) {
    testWidgets('usa default.webp cuando la URL es ${url ?? 'null'}', (
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
