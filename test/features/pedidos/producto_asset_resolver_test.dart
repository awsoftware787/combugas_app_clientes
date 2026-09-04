import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/pedidos/presentation/producto_asset_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('todos los productos sin URL usan default.webp', () {
    for (final id in <int>[
      ProductoIds.cilindro30,
      ProductoIds.cilindro45,
      ProductoIds.estacionario,
      ProductoIds.garrafonNatural,
      ProductoIds.garrafonAlcalino,
      ProductoIds.sixNatural,
      ProductoIds.sixAlcalino,
      999,
    ]) {
      expect(
        ProductoAssetResolver.resolve(
          productoId: id,
          servicioId: ServicioIds.gas,
        ),
        AppAssets.productFallback,
      );
    }

    expect(
      ProductoAssetResolver.resolve(
        productoId: 20,
        servicioId: ServicioIds.croquetas,
        presentacion: 'BULTO ADULTO 20 KG',
      ),
      AppAssets.productFallback,
    );
  });
}
