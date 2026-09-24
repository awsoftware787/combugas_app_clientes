import '../../../core/constants/app_assets.dart';
import '../models/item_pedido.dart';
import '../models/producto.dart';

/// Fuente única de verdad para la imagen local usada cuando no hay URL remota.
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
  }) => AppAssets.productFallback;
}
