import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../models/item_pedido.dart';
import '../models/producto.dart';
import '../presentation/producto_asset_resolver.dart';
import '../presentation/producto_icon_url.dart';

/// Imagen de producto compartida por catálogo, carrito, confirmación y detalle.
class ProductoIcono extends StatelessWidget {
  ProductoIcono.producto({
    super.key,
    this.imageKey,
    required Producto producto,
    this.fit = BoxFit.contain,
  }) : urlIcono = producto.urlIcono,
       fallbackAsset = ProductoAssetResolver.forProducto(producto);

  ProductoIcono.item({
    super.key,
    this.imageKey,
    required ItemPedido item,
    Producto? productoCatalogo,
    bool genericFallback = false,
    this.fit = BoxFit.contain,
  }) : urlIcono = productoCatalogo?.urlIcono ?? item.urlIcono,
       fallbackAsset =
           genericFallback
               ? AppAssets.productFallback
               : productoCatalogo != null
               ? ProductoAssetResolver.forProducto(productoCatalogo)
               : ProductoAssetResolver.forItem(item);

  final Key? imageKey;
  final String? urlIcono;
  final String fallbackAsset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = normalizeProductoIconUrl(urlIcono);
    if (url == null) return _fallback();
    return Image.network(
      url,
      key: imageKey,
      fit: fit,
      loadingBuilder:
          (context, child, progress) =>
              progress == null ? child : _fallback(keyed: false),
      errorBuilder: (_, _, _) => _fallback(keyed: false),
    );
  }

  Widget _fallback({bool keyed = true}) =>
      Image.asset(fallbackAsset, key: keyed ? imageKey : null, fit: fit);
}
