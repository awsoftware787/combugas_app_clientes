import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/pedidos/presentation/producto_asset_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resuelve productos conocidos y fallback centralizado', () {
    expect(_asset(ProductoIds.cilindro30), AppAssets.productCylinder);
    expect(_asset(ProductoIds.cilindro45), AppAssets.productCylinder);
    expect(_asset(ProductoIds.estacionario), AppAssets.productStationaryTank);
    expect(_asset(ProductoIds.garrafonNatural), AppAssets.productWater);
    expect(
      _asset(ProductoIds.garrafonAlcalino),
      AppAssets.productAlkalineWater,
    );
    expect(_asset(ProductoIds.sixNatural), AppAssets.productSixPack);
    expect(_asset(ProductoIds.sixAlcalino), AppAssets.productAlkalineSixPack);
    expect(_asset(999), AppAssets.productFallback);
  });

  test('croquetas dinámicas usan servicio y presentación', () {
    expect(
      ProductoAssetResolver.resolve(
        productoId: 20,
        servicioId: ServicioIds.croquetas,
        presentacion: 'BULTO ADULTO 20 KG',
      ),
      AppAssets.productDogFoodBulk,
    );
    expect(
      ProductoAssetResolver.resolve(
        productoId: 21,
        servicioId: ServicioIds.croquetas,
        presentacion: 'BOLSA CACHORRO',
      ),
      AppAssets.productDogFoodBag,
    );
    expect(
      ProductoAssetResolver.resolve(
        productoId: 999,
        servicioId: 0,
        descripcion: 'BULTO DE 20KG',
      ),
      AppAssets.productDogFoodBulk,
    );
  });
}

String _asset(int id) =>
    ProductoAssetResolver.resolve(productoId: id, servicioId: ServicioIds.gas);
