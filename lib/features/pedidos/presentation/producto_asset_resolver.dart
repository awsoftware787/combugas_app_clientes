import '../../../core/constants/app_assets.dart';
import '../models/item_pedido.dart';
import '../models/producto.dart';

/// Fuente única de verdad para las imágenes de productos.
abstract final class ProductoAssetResolver {
  static String forProducto(Producto producto) => resolve(
    productoId: producto.id,
    servicioId: producto.servicioId,
    descripcion: producto.descripcion,
    presentacion: producto.presentacion,
  );

  static String forItem(ItemPedido item) => resolve(
    productoId: item.productoId,
    servicioId: item.servicioId,
    descripcion: item.descripcion,
    presentacion: item.presentacion,
  );

  static String resolve({
    required int productoId,
    required int servicioId,
    String descripcion = '',
    String presentacion = '',
  }) {
    switch (productoId) {
      case ProductoIds.cilindro30:
      case ProductoIds.cilindro45:
        return AppAssets.productCylinder;
      case ProductoIds.garrafonNatural:
        return AppAssets.productWater;
      case ProductoIds.garrafonAlcalino:
        return AppAssets.productAlkalineWater;
      case ProductoIds.sixNatural:
        return AppAssets.productSixPack;
      case ProductoIds.sixAlcalino:
        return AppAssets.productAlkalineSixPack;
      case ProductoIds.estacionario:
        return AppAssets.productStationaryTank;
    }

    // El catálogo Android no define IDs constantes para croquetas: el servicio
    // identifica la familia y la presentación determina bolsa o bulto.
    if (servicioId == ServicioIds.croquetas) {
      final text = '$presentacion $descripcion'.toUpperCase();
      if (text.contains('BULTO')) return AppAssets.productDogFoodBulk;
      if (text.contains('BOLSA')) return AppAssets.productDogFoodBag;
    }
    return AppAssets.productFallback;
  }
}
