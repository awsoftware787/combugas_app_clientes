import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
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
    this.showLoadingSkeleton = false,
  }) : urlIcono = producto.urlIcono,
       fallbackAsset = ProductoAssetResolver.forProducto(producto);

  ProductoIcono.item({
    super.key,
    this.imageKey,
    required ItemPedido item,
    Producto? productoCatalogo,
    bool genericFallback = false,
    this.fit = BoxFit.contain,
    this.showLoadingSkeleton = false,
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
  final bool showLoadingSkeleton;

  @override
  Widget build(BuildContext context) {
    final url = normalizeProductoIconUrl(urlIcono);
    if (url == null) return _fallback();
    return Image.network(
      url,
      key: imageKey,
      fit: fit,
      frameBuilder: showLoadingSkeleton ? _buildFrame : null,
      loadingBuilder:
          showLoadingSkeleton
              ? null
              : (context, child, progress) =>
                  progress == null ? child : _fallback(keyed: false),
      errorBuilder: (_, _, _) => _fallback(keyed: false),
    );
  }

  Widget _fallback({bool keyed = true}) => Image.asset(
    fallbackAsset,
    key: keyed ? imageKey : null,
    fit: fit,
    frameBuilder: showLoadingSkeleton ? _buildFrame : null,
  );

  Widget _buildFrame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) =>
      wasSynchronouslyLoaded || frame != null
          ? child
          : const _ProductImageSkeleton();
}

class _ProductImageSkeleton extends StatefulWidget {
  const _ProductImageSkeleton();

  @override
  State<_ProductImageSkeleton> createState() => _ProductImageSkeletonState();
}

class _ProductImageSkeletonState extends State<_ProductImageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.65,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando imagen del producto',
    child: Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        heightFactor: 0.85,
        child: FadeTransition(
          opacity: _opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    ),
  );
}
